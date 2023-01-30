#encoding: utf-8
class SolvedquestionsController < ApplicationController
  before_action :signed_in_user_danger, only: [:create, :update]
  before_action :non_admin_user, only: [:create, :update]
  
  before_action :get_question, only: [:create, :update]
  
  before_action :online_chapter, only: [:create, :update]
  before_action :unlocked_chapter, only: [:create, :update]
  before_action :first_try, only: [:create]
  before_action :not_first_try_not_solved, only: [:update]
  before_action :waited_enough_time, only: [:update]

  # Try to solve a question (first time)
  def create
    @solvedquestion = Solvedquestion.new
    @solvedquestion.user = current_user.sk
    @solvedquestion.question = @question
    
    if check_answer(true)
      @question.nb_tries = @question.nb_tries+1
      if @solvedquestion.correct
        @question.nb_first_guesses = @question.nb_first_guesses+1
      end
      @question.save
      
      # We update chapter.nb_tries if it is the first question that this user tries
      already = false
      @chapter.questions.where("id != ?", @question.id).each do |q|
        already = true if(Solvedquestion.where(:user => current_user.sk, :question => q).count > 0)
      end
      
      unless already
        @chapter.nb_tries = @chapter.nb_tries+1
        @chapter.save
      end

      redirect_to chapter_path(@chapter, :type => 5, :which => @question.id)
    end
  end

  # Try to solve a question (next times)
  def update    
    if check_answer(false)
      redirect_to chapter_path(@chapter, :type => 5, :which => @question.id)
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

  # Check that this is the first try of current user
  def first_try
    previous = Solvedquestion.where(:question_id => @question, :user_id => current_user.sk).count
    if previous > 0
      redirect_to chapter_path(@chapter, :type => 5, :which => @question.id)
    end
  end
  
  # Check that this is not the first try of current user and that he did not solve the question already
  def not_first_try_not_solved
    @solvedquestion = Solvedquestion.where(:user => current_user.sk, :question => @question).first
    if @solvedquestion.nil? || @solvedquestion.correct
      redirect_to chapter_path(@chapter, :type => 5, :which => @question.id)
    end
  end
  
  # Check that current user waited enough (if needed) before trying again
  def waited_enough_time
    if @solvedquestion.nb_guess >= 3 && DateTime.now < @solvedquestion.updated_at + 175
      redirect_to chapter_path(@chapter, :type => 5, :which => @question.id)
    end
  end

  # Check that the chapter is online
  def online_chapter
    return if check_offline_object(@chapter)
  end

  # Check that the prerequisites of the chapter have been completed
  def unlocked_chapter
    unless @chapter.section.fondation
      @chapter.prerequisites.each do |p|
        if (!current_user.sk.chapters.exists?(p.id))
          render 'errors/access_refused' and return
        end
      end
    end
  end
  
  ########## HELPER METHODS ##########
  
  # Helper method to check if the given answer is correct
  def check_answer(first_sub)
    if @question.is_qcm # QCM
      @solvedquestion.guess = 0.0
      @solvedquestion.nb_guess = (first_sub ? 1 : @solvedquestion.nb_guess + 1)
      good_guess = true
      diff_sub = first_sub
      @solvedquestion.resolution_time = DateTime.now
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
            if !diff_sub && !@solvedquestion.items.exists?(c.id)
              diff_sub = true
            end
          else # Answered "false"
            if c.ok
              good_guess = false
            end
            if !diff_sub && @solvedquestion.items.exists?(c.id)
              diff_sub = true
            end
          end
        end

        # If the same answer as the previous one: we don't count it
        if !diff_sub
          redirect_to chapter_path(@chapter, :type => 5, :which => @question.id)
          return false
        end

        if good_guess # Correct
          @solvedquestion.correct = true
          @solvedquestion.save
          @solvedquestion.items.clear
        else # Incorrect
          @solvedquestion.correct = false
          @solvedquestion.save
          @solvedquestion.items.clear
          @question.items.each do |c|
            if answer[c.id.to_s]
              @solvedquestion.items << c
            end
          end
        end

      else # Unique answer
        if !params[:ans]
          flash[:danger] = "Veuillez cocher une réponse."
          redirect_to chapter_path(@chapter, :type => 5, :which => @question.id)
          return false
        end
        
        # If the same answer as the previous one: we don't count it
        if !first_sub && params[:ans].to_i == @solvedquestion.items.first.id
          redirect_to chapter_path(@chapter, :type => 5, :which => @question.id)
          return false
        end
        
        rep = @question.items.where(:ok => true).first

        if rep.id == params[:ans].to_i
          @solvedquestion.correct = true
          @solvedquestion.save
          @solvedquestion.items.clear
        else
          @solvedquestion.correct = false
          @solvedquestion.save
            
          item = Item.find_by_id(params[:ans])
          @solvedquestion.items.clear
          @solvedquestion.items << item
        end
      end
    else # EXERCISE
      if @question.decimal
        guess = params[:solvedquestion][:guess].gsub(",",".").gsub(" ","").to_f # Replace ',' by '.' and remove white spaces (possible after comma)
      else
        guess = params[:solvedquestion][:guess].gsub(" ","").to_i # Remove ',', '.' and ' ' in case of "12 345" instead of "12345"
      end
      if first_sub || @solvedquestion.guess != guess
        @solvedquestion.nb_guess = (first_sub ? 1 : @solvedquestion.nb_guess + 1)
        @solvedquestion.guess = guess
        @solvedquestion.resolution_time = DateTime.now

        if @question.decimal
          @solvedquestion.correct = ((@question.answer - guess).abs < 0.001)
        else
          @solvedquestion.correct = (@question.answer.to_i == guess)
        end
        @solvedquestion.save
      end
    end

    if @solvedquestion.correct
      point_attribution(current_user.sk, @question)
    end
    
    return true
  end

  # Helper method to give points of a question to a user
  def point_attribution(user, question)
    pt = question.value

    partials = user.pointspersections

    if !question.chapter.section.fondation
      user.rating = user.rating + pt
      user.save
    end

    partial = partials.where(:section_id => question.chapter.section.id).first
    partial.points = partial.points + pt
    partial.save
  end

end
