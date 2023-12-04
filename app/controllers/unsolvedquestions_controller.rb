#encoding: utf-8
class UnsolvedquestionsController < ApplicationController
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
    @unsolvedquestion = Unsolvedquestion.new(:user => current_user.sk, :question => @question)
    res = check_answer(true)
    if res != "skip"
      @question.update_attribute(:nb_tries, @question.nb_tries+1)
      if res == "correct"
        @question.update_attribute(:nb_first_guesses, @question.nb_first_guesses+1)
      end
      
      # We update chapter.nb_tries if it is the first question that this user tries
      other_questions = @chapter.questions.where("id != ?", @question.id).select("id")
      if Solvedquestion.where(:user => current_user.sk, :question => other_questions).count + Unsolvedquestion.where(:user => current_user.sk, :question => other_questions).count == 0
        @chapter.update_attribute(:nb_tries, @chapter.nb_tries+1)
      end

      redirect_to chapter_path(@chapter, :type => 5, :which => @question.id)
    end
  end

  # Try to solve a question (next times)
  def update    
    res = check_answer(false)
    if res != "skip"
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
    if Solvedquestion.where(:user => current_user.sk, :question => @question).count + Unsolvedquestion.where(:user => current_user.sk, :question => @question).count > 0
      redirect_to chapter_path(@chapter, :type => 5, :which => @question.id)
    end
  end
  
  # Check that this is not the first try of current user and that he did not solve the question already
  def not_first_try_not_solved
    if Solvedquestion.where(:user => current_user.sk, :question => @question).count > 0 # already solved
      redirect_to chapter_path(@chapter, :type => 5, :which => @question.id)
    end
    @unsolvedquestion = Unsolvedquestion.where(:user => current_user.sk, :question => @question).first
    return if check_nil_object(@unsolvedquestion)
  end
  
  # Check that current user waited enough (if needed) before trying again
  def waited_enough_time
    if @unsolvedquestion.nb_guess >= 3 && DateTime.now < @unsolvedquestion.last_guess_time + 175
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
    correct = nil
    if @question.is_qcm # QCM
      @unsolvedquestion.guess = 0.0
      @unsolvedquestion.nb_guess = (first_sub ? 1 : @unsolvedquestion.nb_guess + 1)
      good_guess = true
      diff_sub = first_sub
      @unsolvedquestion.last_guess_time = DateTime.now
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
          redirect_to chapter_path(@chapter, :type => 5, :which => @question.id)
          return "skip"
        end

        if good_guess
          correct = true
          create_solvedquestion_from_unsolvedquestion
        else
          correct = false
          @unsolvedquestion.save
          @unsolvedquestion.items.clear
          @question.items.each do |c|
            if answer[c.id.to_s]
              @unsolvedquestion.items << c
            end
          end
        end

      else # Unique answer
        if !params[:ans]
          flash[:danger] = "Veuillez cocher une réponse."
          redirect_to chapter_path(@chapter, :type => 5, :which => @question.id)
          return "skip"
        end
        
        # If the same answer as the previous one: we don't count it
        if !first_sub && params[:ans].to_i == @unsolvedquestion.items.first.id
          redirect_to chapter_path(@chapter, :type => 5, :which => @question.id)
          return "skip"
        end
        
        rep = @question.items.where(:ok => true).first

        if rep.id == params[:ans].to_i
          correct = true
          create_solvedquestion_from_unsolvedquestion
        else
          correct = false
          @unsolvedquestion.save
            
          item = Item.find_by_id(params[:ans])
          @unsolvedquestion.items.clear
          @unsolvedquestion.items << item
        end
      end
    else # EXERCISE
      if @question.decimal
        guess = params[:unsolvedquestion][:guess].gsub(",",".").gsub(" ","").to_f # Replace ',' by '.' and remove white spaces (possible after comma)
      else
        guess = params[:unsolvedquestion][:guess].gsub(" ","").to_i # Remove ',', '.' and ' ' in case of "12 345" instead of "12345"
      end
      
      if !first_sub && @unsolvedquestion.guess == guess
        redirect_to chapter_path(@chapter, :type => 5, :which => @question.id)
        return "skip"
      end
      
      @unsolvedquestion.nb_guess = (first_sub ? 1 : @unsolvedquestion.nb_guess + 1)
      @unsolvedquestion.guess = guess
      @unsolvedquestion.last_guess_time = DateTime.now

      if @question.decimal
        correct = ((@question.answer - guess).abs < 0.001)
      else
        correct = (@question.answer.to_i == guess)
      end
      
      if correct
        create_solvedquestion_from_unsolvedquestion
      else
        @unsolvedquestion.save
      end
    end

    if correct
      point_attribution(current_user.sk, @question)
    end
    
    return (correct ? "correct" : "wrong")
  end
  
  # Helper method to create Solvedquestion from Unsolvedquestion
  def create_solvedquestion_from_unsolvedquestion
    Solvedquestion.create(:user            => @unsolvedquestion.user,
                          :question        => @unsolvedquestion.question,
                          :guess           => @unsolvedquestion.guess, # to be removed
                          :nb_guess        => @unsolvedquestion.nb_guess,
                          :correct         => true, # to be removed
                          :resolution_time => @unsolvedquestion.last_guess_time)
    
    unless @unsolvedquestion.id.nil?
      @unsolvedquestion.destroy
    end
  end

  # Helper method to give points of a question to a user
  def point_attribution(user, question)
    pt = question.value

    partials = user.pointspersections

    if !question.chapter.section.fondation
      user.update_attribute(:rating, user.rating + pt)
    end

    partial = partials.where(:section_id => question.chapter.section.id).first
    partial.update_attribute(:points, partial.points + pt)
  end

end
