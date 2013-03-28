#encoding: utf-8
class QcmsController < QuestionsController
  before_filter :signed_in_user
  before_filter :admin_user,
    only: [:destroy, :update, :edit, :new, :create, :order_minus, :order_plus, :manage_choices, :remove_choice, :add_choice, :switch_choice, :update_choice, :put_online]
  before_filter :online_qcm,
    only: [:add_choice, :remove_choice]

  def new
    @chapter = Chapter.find(params[:chapter_id])
    @qcm = Qcm.new
  end

  def edit
    @qcm = Qcm.find(params[:id])
  end

  def create
    @chapter = Chapter.find(params[:chapter_id])
    @qcm = Qcm.new
    if @chapter.nil?
      flash[:error] = "Chapitre inexistant."
      render 'new' and return
    end
    if @chapter.online
      @qcm.online = false
    else
      @qcm.online = true
    end
    @qcm.chapter = @chapter
    @qcm.statement = params[:qcm][:statement]
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

  def update
    @qcm = Qcm.find(params[:id])
    @qcm.statement = params[:qcm][:statement]
    if !@qcm.chapter.online || !@qcm.online
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
                flash[:notice] = "Attention, il y avait plusieurs réponses correctes à ce QCM, seule la première a été gardée."
                c.save
              end
              i = i+1
            end
          end
          if @qcm.choices.count > 0 && i == 0
            # There is no good answer
            flash[:notice] = "Attention, il n'y avait aucune réponse correcte à ce QCM, une réponse correcte a été rajoutée aléatoirement."
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

  def destroy
    @qcm = Qcm.find(params[:id])
    @chapter = @qcm.chapter
    @qcm.destroy
    flash[:success] = "QCM supprimé."
    Solvedqcm.where(:qcm_id => params[:id]).each do |s|
      s.destroy
    end
    Choice.where(:qcm_id => params[:id]).each do |c|
      c.destroy
    end
    redirect_to @chapter
  end
  
  def manage_choices
    @qcm = Qcm.find(params[:qcm_id])
  end
  
  def remove_choice
    @choice = Choice.find(params[:id])
    if !@qcm.many_answers && @choice.ok && @qcm.choices.count > 1
      # No more good answer
      # We put one in random to true
      @choice.destroy
      @choice2 = @qcm.choices.last
      @choice2.ok = true
      @choice2.save
      flash[:notice] = "Vous avez supprimé une réponse correcte : une autre a été mise correcte à la place par défaut."
    else
      @choice.destroy
    end
    redirect_to qcm_manage_choices_path(params[:qcm_id])
  end
  
  def add_choice
    @choice = Choice.new
    @choice.qcm_id = params[:qcm_id]
    @choice.ok = params[:choice][:ok]
    @choice.ans = params[:choice][:ans]
    if !@qcm.many_answers && @choice.ok && @qcm.choices.count > 0
      flash[:notice] = "La réponse correcte a maintenant changé (une seule réponse est possible pour ce qcm)."
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
      flash[:notice] = "Cette réponse est mise correcte par défaut. Celle-ci redeviendra erronée lorsque vous rajouterez la réponse correcte."
      @choice.ok = true
    end
    unless @choice.save
      flash[:error] = "Un choix ne peut être vide."
    end
    redirect_to qcm_manage_choices_path(params[:qcm_id])
  end
  
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
  
  def update_choice
    @choice = Choice.find(params[:id])
    @choice.ans = params[:choice][:ans]
    if @choice.save
      flash[:success] = "Réponse modifiée."
    else
      flash[:error] = "Un choix ne peut être vide."
    end
    redirect_to qcm_manage_choices_path(params[:qcm_id])
  end

  def order_minus
    @qcm = Qcm.find(params[:qcm_id])
    order_op(true, false, @qcm)
  end

  def order_plus
    @qcm = Qcm.find(params[:qcm_id])
    order_op(false, false, @qcm)
  end
  
  def put_online
    @qcm = Qcm.find(params[:qcm_id])
    @qcm.online = true
    @qcm.save
    redirect_to chapter_path(@qcm.chapter, :type => 3, :which => @qcm.id)
  end


  private

  def swap_position(a, b)
    err = nil
    Qcm.transaction do
      x = a.position
      a.position = b.position
      b.position = x
      a.save(validate: false)
      b.save(validate: false)
      unless a.valid? and b.valid?
        erra = get_errors(a)
        errb = get_errors(b)
        if erra.nil?
          if errb.nil?
            err = "Quelque chose a mal tourné."
          else
            err = "#{errb} pour #{b.title}"
          end
        else
          # if a is not valid b.valid? is not executed
          err = "#{erra} pour #{a.title}"
        end
        raise ActiveRecord::Rollback
      end
    end
    return err
  end


  def admin_user
    redirect_to root_path unless current_user.admin?
  end
  
  def online_qcm
    @qcm = Qcm.find(params[:qcm_id])
    if @qcm.online && @qcm.chapter.online
      redirect_to chapter_path(@qcm.chapter)
    end
  end

  def maximum(a, b)
    if a > b
      return a
    else
      return b
    end
  end
end
