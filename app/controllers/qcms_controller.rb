#encoding: utf-8
class QcmsController < QuestionsController
  before_action :signed_in_user, only: [:new, :edit, :manage_choices, :explanation]
  before_action :signed_in_user_danger, only: [:create, :update, :destroy, :remove_choice, :add_choice, :switch_choice, :update_choice, :order_minus, :order_plus, :put_online, :update_explanation]
  before_action :admin_user
  before_action :online_qcm, only: [:add_choice, :remove_choice]
  before_action :root_qcm_user, only: [:destroy]

  # Créer un qcm
  def new
    @chapter = Chapter.find(params[:chapter_id])
    @qcm = Qcm.new
  end

  # Editer un qcm
  def edit
    @qcm = Qcm.find(params[:id])
  end

  # Créer un qcm 2
  def create
    @chapter = Chapter.find(params[:chapter_id])
    @qcm = Qcm.new
    @qcm.online = false
    @qcm.chapter = @chapter
    @qcm.statement = params[:qcm][:statement]
    @qcm.level = params[:qcm][:level]
    if @chapter.section.fondation?
      @qcm.level = 0
    end
    @qcm.explanation = ""
    if params[:qcm][:many_answers] == '1'
      @qcm.many_answers = true
    else
      @qcm.many_answers = false
    end
    before = 0
    before2 = 0
    unless @chapter.exercises.empty?
      need = @chapter.exercises.order('position').reverse_order.first
      before = need.position
    end
    unless @chapter.qcms.empty?
      need = @chapter.qcms.order('position').reverse_order.first
      before2 = need.position
    end
    @qcm.position = maximum(before, before2) + 1
    if @qcm.save
      flash[:success] = "QCM ajouté."
      redirect_to qcm_manage_choices_path(@qcm)
    else
      render 'new'
    end
  end

  # Editer un qcm 2
  def update
    @qcm = Qcm.find(params[:id])
    @qcm.statement = params[:qcm][:statement]
    unless @qcm.online
      @qcm.level = params[:qcm][:level]
      if @qcm.chapter.section.fondation?
        @qcm.level = 0
      end
      if params[:qcm][:many_answers] == '1'
        @qcm.many_answers = true
      else
        if @qcm.many_answers
          # Must check there is only one true
          i = 0
          @qcm.choices.each do |c|
            if c.ok
              if i > 0
                c.ok = false
                flash[:info] = "Attention, il y avait plusieurs réponses correctes à ce QCM, seule la première a été gardée."
                c.save
              end
              i = i+1
            end
          end
          if @qcm.choices.count > 0 && i == 0
            # There is no good answer
            flash[:info] = "Attention, il n'y avait aucune réponse correcte à ce QCM, une réponse correcte a été rajoutée aléatoirement."
            @choice = @qcm.choices.first
            @choice.ok = true
            @choice.save
          end
        end
        @qcm.many_answers = false
      end
    end
    if @qcm.save

      if @qcm.chapter.online
        redirect_to chapter_path(@qcm.chapter, :type => 3, :which => @qcm.id)
      else
        redirect_to qcm_manage_choices_path(@qcm)
      end
    else
      render 'edit'
    end
  end

  # Supprimer un qcm (plus possible si en ligne)
  def destroy
    @chapter = @qcm.chapter
    @qcm.destroy
    flash[:success] = "QCM supprimé."
    redirect_to @chapter
  end

  # Page pour modifier les choix
  def manage_choices
    @qcm = Qcm.find(params[:qcm_id])
  end

  # Supprimer un choix
  def remove_choice
    @choice = Choice.find(params[:id])
    if !@qcm.many_answers && @choice.ok && @qcm.choices.count > 1
      # No more good answer
      # We put one in random to true
      @choice.destroy
      @choice2 = @qcm.choices.last
      @choice2.ok = true
      @choice2.save
      flash[:info] = "Vous avez supprimé une réponse correcte : une autre a été mise correcte à la place par défaut."
    else
      @choice.destroy
    end
    redirect_to qcm_manage_choices_path(params[:qcm_id])
  end

  # Ajouter un choix
  def add_choice
    @choice = Choice.new
    @choice.qcm_id = params[:qcm_id]
    @choice.ok = params[:choice][:ok]
    @choice.ans = params[:choice][:ans]
    if !@qcm.many_answers && @choice.ok && @qcm.choices.count > 0
      flash[:info] = "La réponse correcte a maintenant changé (une seule réponse est possible pour ce qcm)."
      # Two good answer
      # We put the other one to false
      @qcm.choices.each do |f|
        if f.ok
          f.ok = false
          f.save
        end
      end
    end
    if !@qcm.many_answers && !@choice.ok && @qcm.choices.count == 0
      flash[:info] = "Cette réponse est mise correcte par défaut. Celle-ci redeviendra erronée lorsque vous rajouterez la réponse correcte."
      @choice.ok = true
    end
    unless @choice.save
      flash[:info] = "Un choix ne peut être vide."
    end
    redirect_to qcm_manage_choices_path(params[:qcm_id])
  end

  # Modifier la véracité d'un choix
  def switch_choice
    @choice = Choice.find(params[:id])
    @qcm = @choice.qcm
    if !@qcm.many_answers
      @qcm.choices.each do |f|
        if f.ok
          f.ok = false
          f.save
        end
      end
      @choice.ok = true
    else
      @choice.ok = !@choice.ok
    end
    @choice.save
    redirect_to qcm_manage_choices_path(params[:qcm_id])
  end

  # Modifier un choix
  def update_choice
    @choice = Choice.find(params[:id])
    @choice.ans = params[:choice][:ans]
    if @choice.save
      flash[:success] = "Réponse modifiée."
    else
      flash[:danger] = "Un choix ne peut être vide."
    end
    redirect_to qcm_manage_choices_path(params[:qcm_id])
  end

  # Déplacer
  def order_minus
    @qcm = Qcm.find(params[:qcm_id])
    order_op(true, false, @qcm)
  end

  # Déplacer
  def order_plus
    @qcm = Qcm.find(params[:qcm_id])
    order_op(false, false, @qcm)
  end

  # Mettre en ligne
  def put_online
    @qcm = Qcm.find(params[:qcm_id])
    @qcm.online = true
    @qcm.save
    @section = @qcm.chapter.section
    @section.max_score = @section.max_score + @qcm.value
    @section.save
    redirect_to chapter_path(@qcm.chapter, :type => 3, :which => @qcm.id)
  end

  # Modifier l'explication
  def explanation
    @qcm = Qcm.find(params[:qcm_id])
  end

  # Modifier l'explication 2
  def update_explanation
    @qcm = Qcm.find(params[:qcm_id])
    @qcm.explanation = params[:qcm][:explanation]
    if @qcm.save
      flash[:success] = "Explication modifiée."
      redirect_to chapter_path(@qcm.chapter, :type => 3, :which => @qcm.id)
    else
      render 'explanation'
    end
  end

  ########## PARTIE PRIVEE ##########
  private

  # Il faut être root pour supprimer un qcm en ligne
  def root_qcm_user
    @qcm = Qcm.find(params[:id])
    redirect_to chapter_path(@qcm.chapter, :type => 3, :which => @qcm.id) if (!current_user.sk.root && @qcm.online)
  end

  # Vérifie que le qcm est en ligne
  def online_qcm
    @qcm = Qcm.find(params[:qcm_id])
    if @qcm.online
      redirect_to chapter_path(@qcm.chapter)
    end
  end

  # Bete maximum
  def maximum(a, b)
    if a > b
      return a
    else
      return b
    end
  end
end
