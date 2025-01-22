#encoding: utf-8
class UnsolvedquestionsController < ApplicationController
  include ChapterConcern
  
  before_action :signed_in_user_danger, only: [:create, :update]
  before_action :non_admin_user, only: [:update]
  
  before_action :get_question, only: [:create, :update]
  
  before_action :online_chapter, only: [:create, :update]
  before_action :user_can_see_chapter_questions, only: [:create, :update]
  before_action :first_try_of_user, only: [:create]
  before_action :user_did_not_solve_question, only: [:update]
  before_action :not_first_try_of_user, only: [:update]
  before_action :user_waited_enough_time, only: [:update]

  # Try to solve a question (first time)
  def create
    @unsolvedquestion = Unsolvedquestion.new(:user => current_user, :question => @question)
    for_fun = (current_user.admin? || current_user.solvedquestions.where(:question => @question).count > 0)
    res = check_answer(true, for_fun)
    return if res == "skip"
    
    unless for_fun
      if res == "correct"
        @question.update(:nb_first_guesses => @question.nb_first_guesses + 1,
                         :nb_correct       => @question.nb_correct + 1)
        mark_chapter_as_solved_if_needed
      else
        @question.update(:nb_wrong         => @question.nb_wrong + 1)
      end
        
      # We update chapter.nb_tries if it is the first question that this user tries
      other_questions = @chapter.questions.where("id != ?", @question.id).select("id")
      if current_user.solvedquestions.where(:question => other_questions).count + current_user.unsolvedquestions.where(:question => other_questions).count == 0
        @chapter.update_attribute(:nb_tries, @chapter.nb_tries + 1)
      end
    end
    
    if res == "correct"
      flash[:success] = "Bonne réponse !"
      redirect_to chapter_question_path(@chapter, @question, :answer => 1)
    else
      flash[:danger] = "Mauvaise réponse..."
      redirect_to chapter_question_path(@chapter, @question)
    end
  end

  # Try to solve a question (next times)
  def update    
    res = check_answer(false)
    return if res == "skip"
    
    if res == "correct"
      @question.update(:nb_correct => @question.nb_correct + 1,
                       :nb_wrong   => @question.nb_wrong - 1)
      mark_chapter_as_solved_if_needed
    end
    
    if res == "correct"
      flash[:success] = "Bonne réponse !"
      redirect_to chapter_question_path(@chapter, @question, :answer => 1)
    else
      flash[:danger] = "Mauvaise réponse..."
      redirect_to chapter_question_path(@chapter, @question)
    end
  end

  private
  
  ########## GET METHODS ##########
  
  # Get the question
  def get_question
    @question = Question.find_by_id(params[:question_id])
    return if check_nil_object(@question)
    @chapter = @question.chapter
  end
  
  ########## CHECK METHODS ##########

  # Check that this is the first try of current user (or that he already solved the question)
  def first_try_of_user
    if current_user.unsolvedquestions.where(:question => @question).count > 0
      redirect_to chapter_question_path(@chapter, @question)
    end
  end
  
  # Check that the current user did not solve the question already
  def user_did_not_solve_question
    if current_user.solvedquestions.where(:question => @question).count > 0 # already solved
      redirect_to chapter_question_path(@chapter, @question)
    end
  end
  
  # Check that this is not the first try of current user
  def not_first_try_of_user
    @unsolvedquestion = current_user.unsolvedquestions.where(:question => @question).first
    return if check_nil_object(@unsolvedquestion)
  end
  
  # Check that current user waited enough (if needed) before trying again
  def user_waited_enough_time
    if @unsolvedquestion.nb_guess >= 3 && DateTime.now < @unsolvedquestion.last_guess_time + 175
      redirect_to chapter_question_path(@chapter, @question)
    end
  end

  # Check that the chapter is online
  def online_chapter
    return if check_offline_object(@chapter)
  end
  
  ########## HELPER METHODS ##########
  
  # Helper method to check if the given answer is correct
  def check_answer(first_sub, for_fun = false)
    correct = nil
    @unsolvedquestion.nb_guess = (first_sub ? 1 : @unsolvedquestion.nb_guess + 1)
    @unsolvedquestion.last_guess_time = DateTime.now
    if @question.is_qcm # QCM
      @unsolvedquestion.guess = 0.0
      good_guess = true
      diff_sub = first_sub
      if @question.many_answers # Many answers possible
        if params[:ans]
          answer = params[:ans]
        else
          answer = {}
        end

        @question.items.each do |c|
          if answer[c.id.to_s] # Answered "true"
            if !c.ok
              good_guess = false
            end
            if !diff_sub && !@unsolvedquestion.items.exists?(c.id)
              diff_sub = true
            end
          else # Answered "false"
            if c.ok
              good_guess = false
            end
            if !diff_sub && @unsolvedquestion.items.exists?(c.id)
              diff_sub = true
            end
          end
        end

        # If the same answer as the previous one: we don't count it
        if !diff_sub
          flash[:danger] = "Votre réponse est la même que votre réponse précédente."
          redirect_to chapter_question_path(@chapter, @question)
          return "skip"
        end

        correct = good_guess
        unless for_fun
          if correct
            create_solvedquestion_from_unsolvedquestion
          else
            @unsolvedquestion.save
            @unsolvedquestion.items.clear
            @question.items.each do |c|
              if answer[c.id.to_s]
                @unsolvedquestion.items << c
              end
            end
          end
        end

      else # Unique answer
        if !params[:ans]
          flash[:danger] = "Veuillez cocher une réponse."
          redirect_to chapter_question_path(@chapter, @question)
          return "skip"
        end
        
        # If the same answer as the previous one: we don't count it
        if !first_sub && params[:ans].to_i == @unsolvedquestion.items.first.id
          flash[:danger] = "Votre réponse est la même que votre réponse précédente."
          redirect_to chapter_question_path(@chapter, @question)
          return "skip"
        end
        
        rep = @question.items.where(:ok => true).first

        correct = (rep.id == params[:ans].to_i)
        unless for_fun
          if correct
            create_solvedquestion_from_unsolvedquestion
          else
            @unsolvedquestion.save
              
            item = Item.find_by_id(params[:ans])
            @unsolvedquestion.items.clear
            @unsolvedquestion.items << item
          end
        end
      end
    else # EXERCISE
      guess_str = params[:unsolvedquestion][:guess]
      guess_str.gsub!(" ", "") # Remove white spaces (possible after comma for decimal numbers, and possible with "12 345" instead of "12345")
      
      allowed_characters = Set['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '-']
      if @question.decimal
        allowed_characters.add('.') 
        allowed_characters.add(',')
      end
      
      if guess_str.size() == 0
        flash[:danger] = "Votre réponse est vide."
        redirect_to chapter_question_path(@chapter, @question)
        return "skip"
      end
      
      (0..guess_str.size()-1).each do |i|
        if !allowed_characters.include?(guess_str[i])
          flash[:danger] = "La réponse attendue est un nombre #{@question.decimal ? 'réel' : 'entier'}."
          redirect_to chapter_question_path(@chapter, @question)
          return "skip"
        end
      end
      
      if @question.decimal
        guess = guess_str.gsub(",",".").to_f # Replace ',' by '.'
      else
        guess = guess_str.to_i
      end
      
      if !first_sub && @unsolvedquestion.guess == guess
        flash[:danger] = "Votre réponse est la même que votre réponse précédente."
        redirect_to chapter_question_path(@chapter, @question)
        return "skip"
      end
      
      if guess.abs() > 1000000000
        flash[:danger] = "Votre réponse est trop grande (en valeur absolue)."
        redirect_to chapter_question_path(@chapter, @question)
        return "skip"
      end
      
      if @question.decimal
        correct = ((@question.answer - guess).abs < 0.001)
      else
        correct = (@question.answer.to_i == guess)
      end
      
      unless for_fun
        @unsolvedquestion.guess = guess
        if correct
          create_solvedquestion_from_unsolvedquestion
        else
          @unsolvedquestion.save
        end
      end
    end

    if correct && !for_fun
      point_attribution(current_user, @question)
    end
    
    return (correct ? "correct" : "wrong")
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
  
  # Helper method to create Solvedquestion from Unsolvedquestion
  def create_solvedquestion_from_unsolvedquestion
    Solvedquestion.create(:user            => @unsolvedquestion.user,
                          :question        => @unsolvedquestion.question,
                          :nb_guess        => @unsolvedquestion.nb_guess,
                          :resolution_time => @unsolvedquestion.last_guess_time)
    
    unless @unsolvedquestion.id.nil?
      @unsolvedquestion.destroy
    end
  end

  # Helper method to give points of a question to a user
  def point_attribution(user, question)
    pt = question.value
    
    if !question.chapter.section.fondation && pt > 0
      Globalstatistic.get.update_after_question_solved(user.rating, pt)
      user.update_attribute(:rating, user.rating + pt)
      partial = user.pointspersections.where(:section_id => question.chapter.section_id).first
      partial.update_attribute(:points, partial.points + pt)
    end
  end
end
