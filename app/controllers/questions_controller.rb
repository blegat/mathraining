#encoding: utf-8
class QuestionsController < ApplicationController
  include ChapterConcern
  
  before_action :signed_in_user, only: [:new, :edit, :manage_items, :edit_explanation, :show_answer, :check_answer]
  before_action :signed_in_user_danger, only: [:create, :update, :destroy, :order, :put_online, :update_explanation]
  before_action :user_not_in_skin, only: [:check_answer]
  
  before_action :get_question, only: [:show, :edit, :update, :destroy, :manage_items, :order, :put_online, :edit_explanation, :update_explanation, :show_answer, :check_answer]
  before_action :get_chapter, only: [:show, :new, :create]
  
  before_action :question_of_chapter, only: [:show]
  before_action :user_can_see_chapter, only: [:show, :show_answer, :check_answer] # Maybe not necessary because of user_can_see_question?
  before_action :user_can_see_question, only: [:show, :show_answer, :check_answer]
  before_action :user_can_update_chapter, only: [:new, :edit, :create, :update, :destroy, :manage_items, :edit_explanation, :order, :put_online, :update_explanation]
  before_action :online_question, only: [:show_answer, :check_answer]
  before_action :offline_question, only: [:destroy]
  before_action :user_can_see_answer, only: [:show_answer]

  # Show a question (inside a chapter)
  def show
  end

  # Create a question (show the form)
  def new
    @question = Question.new
    if params[:qcm] == '1'
      @question.is_qcm = true
    end
  end

  # Update a question (show the form)
  def edit
    if !@question.decimal
      @question.answer = @question.answer.to_i
    end
  end

  # Create a question (send the form)
  def create
    @question = Question.new(:online      => false,
                             :chapter     => @chapter,
                             :statement   => params[:question][:statement],
                             :level       => (@section.fondation? ? 0 : params[:question][:level]),
                             :explanation => "À écrire")
    if params[:question][:is_qcm] == '1'
      @question.is_qcm = true
      @question.many_answers = (params[:question][:many_answers] == '1')
      @question.answer = 0
    else
      @question.is_qcm = false
      if params[:question][:decimal] == '1'
        @question.decimal = true
        @question.answer = params[:question][:answer].gsub(",",".").to_f
      else
        @question.decimal = false
        @question.answer = params[:question][:answer].gsub(",",".").to_i
      end
    end
    before = 0
    unless @chapter.questions.empty?
      need = @chapter.questions.order('position').last
      before = need.position
    end
    @question.position = before + 1
    if @question.save
      flash[:success] = "Exercice ajouté."
      if @question.is_qcm
        redirect_to manage_items_question_path(@question)
      else
        redirect_to chapter_question_path(@chapter, @question)
      end
    else
      render 'new'
    end
  end

  # Update a question (send the form)
  def update
    @question.statement = params[:question][:statement]
    unless @question.online
      @question.level = (@section.fondation? ? 0 : params[:question][:level])
      if @question.is_qcm
        if params[:question][:many_answers] == '1'
          @question.many_answers = true
        else
          if @question.many_answers
            # Must check there is only one true
            i = 0
            @question.items.order(:id).each do |c|
              if c.ok
                if i > 0
                  flash[:info] = "Attention, il y avait plusieurs réponses correctes à cet exercice, seule la première a été gardée."
                  c.update_attribute(:ok, false)
                end
                i = i+1
              end
            end
            if @question.items.count > 0 && i == 0
              # There is no good answer
              flash[:info] = "Attention, il n'y avait aucune réponse correcte à cet exercice, une réponse correcte a été rajoutée aléatoirement."
              @item = @question.items.order(:id).first
              @item.update_attribute(:ok, true)
            end
          end
          @question.many_answers = false
        end
      else
        if params[:question][:decimal] == '1'
          @question.decimal = true
          @question.answer = params[:question][:answer].gsub(",",".").to_f
        else
          @question.decimal = false
          @question.answer = params[:question][:answer].gsub(",",".").to_i
        end
      end
    end
    
    if @question.save
      redirect_to chapter_question_path(@chapter, @question)
    else
      render 'edit'
    end
  end

  # Delete a question
  def destroy
    @question.destroy
    flash[:success] = "Exercice supprimé."
    redirect_to @chapter
  end

  # Show page to manage items of a qcm
  def manage_items
  end

  # Move a question to a new position
  def order
    question2 = @chapter.questions.where("position = ?", params[:new_position]).first
    if !question2.nil? && question2 != @question
      res = swap_position(@question, question2)
      flash[:success] = "Exercice déplacé#{res}." 
    end
    redirect_to chapter_question_path(@chapter, @question)
  end

  # Put a question online
  def put_online
    @question.update_attribute(:online, true)
    @section.update_attribute(:max_score, @section.max_score + @question.value)
    redirect_to chapter_question_path(@chapter, @question)
  end

  # Update the explanation of a question (show the form)
  def edit_explanation
  end

  # Update the explanation of a question (send the form)
  def update_explanation
    if @question.update(:explanation => params[:question][:explanation]) # Do not use update_attribute because it does not trigger validations
      flash[:success] = "Explication modifiée."
      redirect_to chapter_question_path(@chapter, @question)
    else
      render 'edit_explanation'
    end
  end
  
  # Show question answer (we want a trace in the logs) (only in js)
  def show_answer
    respond_to :js
  end
  
  # Check question answer (only in js)
  def check_answer
    @solvedquestion = current_user.admin? ? nil : current_user.solvedquestions.where(:question => @question).first
    @for_fun = current_user.admin? || !@solvedquestion.nil?
    @unsolvedquestion = @for_fun ? nil : current_user.unsolvedquestions.where(:question => @question).first
    @first_sub = @unsolvedquestion.nil?
    
    if !@first_sub && @unsolvedquestion.nb_guess >= 3 && DateTime.now < @unsolvedquestion.last_guess_time + 175
      res = ["skip", "Merci d'attendre les 3 minutes."]
    else
      res = @question.check_answer(@unsolvedquestion, params)
    end
    
    @result = res[0]
    @message = res[1] if @result == "skip"
    
    unless @for_fun
      if @result == "correct"
        @solvedquestion = Solvedquestion.create(:user            => current_user,
                                                :question        => @question,
                                                :nb_guess        => (@first_sub ? 1 : @unsolvedquestion.nb_guess + 1),
                                                :resolution_time => DateTime.now)
        @unsolvedquestion.destroy unless @first_sub
        point_attribution
        @question.update(:nb_first_guesses => @question.nb_first_guesses + (@first_sub ? 1 : 0),
                         :nb_correct       => @question.nb_correct + 1,
                         :nb_wrong         => @question.nb_wrong - (@first_sub ? 0 : 1))
        mark_chapter_as_tried_if_needed
        mark_chapter_as_solved_if_needed
      elsif @result == "wrong"
        @unsolvedquestion = Unsolvedquestion.new(:question => @question, :user => current_user) if @first_sub
        @unsolvedquestion.nb_guess = (@first_sub ? 1 : @unsolvedquestion.nb_guess + 1)
        @unsolvedquestion.last_guess_time = DateTime.now
        if @question.is_qcm
          @unsolvedquestion.guess = 0
          @unsolvedquestion.save
          @unsolvedquestion.items.clear unless @first_sub
          res[1].each do |c|
            @unsolvedquestion.items << c
          end
        else
          @unsolvedquestion.guess = res[1]
          @unsolvedquestion.save
        end
        @question.update(:nb_wrong => @question.nb_wrong + 1) if @first_sub
        mark_chapter_as_tried_if_needed
      end
    end
    respond_to :js
  end

  private
  
  ########## GET METHODS ##########
  
  # Get the question
  def get_question
    @question = Question.find_by_id(params[:id])
    return if check_nil_object(@question)
    @chapter = @question.chapter
    @section = @chapter.section
  end
  
  # Get the chapter
  def get_chapter
    @chapter = Chapter.find_by_id(params[:chapter_id])
    return if check_nil_object(@chapter)
    @section = @chapter.section
  end
  
  ########## CHECK METHODS ##########

  # Check that the question is online
  def online_question
    return if check_offline_object(@question)
  end

  # Check that the question is offline
  def offline_question
    return if check_online_object(@question)
  end
  
  # Check that question belongs to chapter
  def question_of_chapter
    if @question.chapter != @chapter
      render 'errors/access_refused'
    end
  end
  
  # Check that user can see the question
  def user_can_see_question
    if !user_can_see_chapter_exercises(current_user, @chapter) || (!@question.online && !user_can_write_chapter(current_user, @chapter))
      render 'errors/access_refused'
    end
  end
  
  # Check that user can see the answer
  def user_can_see_answer
    @solvedquestion = current_user.admin? ? nil : current_user.solvedquestions.where(:question => @question).first
    if !current_user.admin? && @solvedquestion.nil?
      render 'errors/access_refused'
    end
  end

  ########## HELPER METHODS ##########
  
  # Helper method to give points of the question to current user
  def point_attribution
    pt = @question.value
    if !@section.fondation && pt > 0
      Globalstatistic.get.update_after_question_solved(current_user.rating, pt)
      current_user.update_attribute(:rating, current_user.rating + pt)
      partial = current_user.pointspersections.where(:section => @section).first
      partial.update_attribute(:points, partial.points + pt)
    end
  end
  
  # Helper method to mark the chapter as solved if all questions are solved
  def mark_chapter_as_solved_if_needed
    questions = @chapter.questions.where(:online => true).group(:id).count.keys
    solvedquestions = current_user.solvedquestions.where(:question_id => questions).group(:question_id).count.keys
    if solvedquestions.size == questions.size && !current_user.chapters.exists?(@chapter.id)
      current_user.chapters << @chapter
      @chapter.update_attribute(:nb_completions, @chapter.nb_completions + 1)
    end
  end
  
  # Helper method to mark the chapter as tried if this is the first question that the user tries
  def mark_chapter_as_tried_if_needed
    return unless @first_sub
    other_questions = @chapter.questions.where("id != ?", @question.id).select("id")
    if current_user.solvedquestions.where(:question => other_questions).count + current_user.unsolvedquestions.where(:question => other_questions).count == 0
      @chapter.update_attribute(:nb_tries, @chapter.nb_tries + 1)
    end
  end
end
