#encoding: utf-8
class SolvedquestionsController < ApplicationController
  before_action :signed_in_user_danger, only: [:create, :update]
  before_action :get_question, only: [:create, :update]
  before_action :before_create, only: [:create]
  before_action :before_update, only: [:update]
  before_action :waiting_time, only: [:update]
  before_action :online_chapter
  before_action :unlocked_chapter

  # On tente de résoudre une question (pour la première fois)
  def create
    @link = Solvedquestion.new
    @link.user = current_user.sk
    @link.question = @question
    
    if check_answer(true)
      @question.nb_tries = @question.nb_tries+1
      if @link.correct
        @question.nb_firstguess = @question.nb_firstguess+1
      end
      @question.save
      
      # On augmente chapter.nb_tries si c'est le premier exercice essayé
      already = false
      chapter = @question.chapter
      chapter.questions.where("id != ?", @question.id).each do |q|
        already = true if(Solvedquestion.where(:user => current_user.sk, :question => q).count > 0)
      end
      
      unless already
        chapter.nb_tries = chapter.nb_tries+1
        chapter.save
      end

      redirect_to chapter_path(@question.chapter, :type => 5, :which => @question.id)
    end
  end

  # On tente de résoudre un exercice une nouvelle fois
  def update    
    if check_answer(false)
      redirect_to chapter_path(@question.chapter, :type => 5, :which => @question.id)
    end
  end

  ########## PARTIE PRIVEE ##########
  private
  
  # Retourne la différence (en valeur absolue) entre a et b
  def absolu(a, b)
    if a > b
      return a-b
    else
      return b-a
    end
  end
  
  def get_question
    @question = Question.find_by_id(params[:question_id])
    if @question.nil?
      render 'errors/access_refused' and return
    end
    @chapter = @question.chapter
  end

  # On récupère l'exercice et le chapitre  
  def before_create
    previous = Solvedquestion.where(:question_id => @question, :user_id => current_user.sk).count
    if previous > 0
      redirect_to chapter_path(@chapter, :type => 5, :which => @question.id)
    end
  end
  
  def before_update
    @link = Solvedquestion.where(:user => current_user.sk, :question => @question).first
    if @link.nil? || @link.correct
      redirect_to chapter_path(@chapter, :type => 5, :which => @question.id)
    end
  end
  
  def waiting_time
    if @link.nb_guess >= 3 && DateTime.now.in_time_zone < @link.updated_at + 175
      redirect_to chapter_path(@chapter, :type => 5, :which => @question.id)
    end
  end

  # Il faut que le chapitre soit en ligne
  def online_chapter
    redirect_to root_path unless (current_user.sk.admin? || @chapter.online)
  end

  # Il faut qu'on puisse faire les exercices
  def unlocked_chapter
    if !current_user.sk.admin?
      @chapter.prerequisites.each do |p|
        if (!p.section.fondation && !current_user.sk.chapters.exists?(p))
          redirect_to root_path and return
        end
      end
    end
  end
  
  def check_answer(first_sub)
    if @question.is_qcm
      # QCM
      @link.guess = 0.0
      @link.nb_guess = (first_sub ? 1 : @link.nb_guess + 1)
      good_guess = true
      autre = first_sub
      @link.resolutiontime = DateTime.now
      if @question.many_answers
        # Plusieurs reponses possibles
        if params[:ans]
          answer = params[:ans]
        else
          answer = {}
        end

        @question.items.each do |c|
          if answer[c.id.to_s]
            # Répondu vrai
            if !c.ok
              good_guess = false
            end
            if !first_sub && !@link.items.exists?(c)
              autre = true
            end
          else
            # Répondu faux
            if c.ok
              good_guess = false
            end
            if !first_sub && @link.items.exists?(c)
              autre = true
            end
          end
        end

        # Il s'agit de la même réponse que la précédente : on ne la compte pas
        if !autre
          redirect_to chapter_path(@question.chapter, :type => 5, :which => @question.id)
          return false
        end

        if good_guess
          # Correct
          @link.correct = true
          @link.save
          @link.items.clear
        else
          # Incorrect
          @link.correct = false
          @link.save
          @link.items.clear
          @question.items.each do |c|
            if answer[c.id.to_s]
              @link.items << c
            end
          end
        end

      else
        # Reponse unique
        if !params[:ans]
          flash[:danger] = "Veuillez cocher une réponse."
          redirect_to chapter_path(@question.chapter, :type => 5, :which => @question.id)
          return false
        end
        
        # Il s'agit de la même réponse que la précédente : on ne la compte pas
        if !first_sub && params[:ans].to_i == @link.items.first.id
          redirect_to chapter_path(@question.chapter, :type => 5, :which => @question.id)
          return false
        end
        
        rep = @question.items.where(:ok => true).first

        if rep.id == params[:ans].to_i
          @link.correct = true
          @link.save
          @link.items.clear
        else
          @link.correct = false
          @link.save
            
          item = Item.find_by_id(params[:ans])
          @link.items.clear
          @link.items << item
        end
      end
    else
      # EXO
      if first_sub || @link.guess != params[:solvedquestion][:guess].gsub(",",".").to_f
        @link.nb_guess = (first_sub ? 1 : @link.nb_guess + 1)
        @link.guess = params[:solvedquestion][:guess].gsub(",",".").to_f
        @link.resolutiontime = DateTime.now

        if @question.decimal
          if absolu(@question.answer, @link.guess) < 0.001
            @link.correct = true
          else
            @link.correct = false
          end
        else
          if @question.answer.to_i == @link.guess.to_i
            @link.correct = true
          else
            @link.correct = false
          end
        end
        @link.save
      end
    end

    if @link.correct
      point_attribution(current_user.sk, @question)
    end
    
    return true
  end

  # Attribution des points pour un exercice
  def point_attribution(user, question)
    pt = question.value

    partials = user.pointspersections

    if !question.chapter.section.fondation # Pas un fondement
      user.rating = user.rating + pt
      user.save
    end

    partial = partials.where(:section_id => question.chapter.section.id).first
    partial.points = partial.points + pt
    partial.save
  end

end
