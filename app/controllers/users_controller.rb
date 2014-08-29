#encoding: utf-8
class UsersController < ApplicationController
  before_filter :signed_in_user,
    only: [:destroy, :edit, :update, :create_administrator, :recompute_scores, :notification_new, :notification_update, :notifs_show, :take_skin, :leave_skin]
  before_filter :correct_user,
    only: [:edit, :update]
  before_filter :admin_user,
    only: [:destroy, :notification_new, :notification_update, :take_skin]
  before_filter :root_user,
    only: [:create_administrator, :recompute_scores]
  before_filter :signed_out_user,
    only: [:new, :create, :password_forgotten, :forgot_password]
  before_filter :destroy_admin,
    only: [:destroy]

  def index
  end
  
  def create
    @user = User.new(params[:user])
    @user.key = SecureRandom.urlsafe_base64

    # Don't do email and captcha in development and tests
    @user.email_confirm = !Rails.env.production?

  	if (not Rails.env.production? or verify_recaptcha(:model => @user, :message => "Captcha incorrect")) && @user.save
      if Rails.env.production?
        UserMailer.registration_confirmation(@user.id).deliver
      end

  	  flash[:success] = "Vous allez recevoir un e-mail de confirmation d'ici quelques minutes pour activer votre compte. Vérifiez votre courrier indésirable si celui-ci semble ne pas arriver."
  	  flash[:success] = "Vous êtes inscrit! Veuillez vous connecter."
  	  redirect_to signin_path
  	else
  	  render 'new'
  	end
  end
  def show
    @user = User.find(params[:id])
    if @user.admin && !current_user.sk.root
      redirect_to users_path
    end
  end
  def new
  	@user = User.new
  end
  def edit
  end
  def update
    if @user.update_attributes(params[:user])
      flash[:success] = "Profil mis à jour."
      sign_in @user
      redirect_to root_path
    else
      render 'edit'
    end
  end
  def destroy
    skinner = User.where(skin: @user.id)
    skinner.each do |s|
      s.update_attribute(:skin, 0)
    end
    @user.destroy
    flash[:success] = "Utilisateur supprimé."
    redirect_to users_path
  end

  def create_administrator
    @user = User.find(params[:user_id])
    if @user.admin?
      flash[:error] = "I see what you did here! Mais non ;-)"
    else
      @user.toggle!(:admin)
      skinner = User.where(skin: @user.id)
      skinner.each do |s|
        s.update_attribute(:skin, 0)
      end
      flash[:success] = "Utilisateur promu au rang d'administrateur!"
    end
    redirect_to users_path
  end

  def activate
    @user = User.find(params[:id])
    if !@user.email_confirm && @user.key.to_s == params[:key].to_s
      @user.toggle!(:email_confirm)
      flash[:success] = "Votre compte a bien été activé! Veuillez maintenant vous connecter."
    elsif @user.key.to_s != params[:key].to_s
      flash[:error] = "Le lien d'activation est erroné."
    else
      flash[:notice] = "Ce compte est déjà actif!"
    end
    redirect_to signin_path
  end

  def password_forgotten
    @user = User.find_by_email(params[:user][:email])
    if @user
      @user.update_attribute(:key, SecureRandom.urlsafe_base64)
      UserMailer.forgot_password(@user.id).deliver
  	  flash[:success] = "Vous allez recevoir un e-mail d'ici quelques minutes pour que vous puissiez changer de mot de passe. Vérifiez votre courrier indésirable si celui-ci semble ne pas arriver."
    else
      flash[:error] = 'Aucun utilisateur ne possède cet adresse.'
    end
    redirect_to signin_path
  end

  def recup_password
    @user = User.find(params[:id])
    if @user.key.to_s != params[:key].to_s
      flash[:error] = "Ce lien n'est pas correct."
      redirect_to root_path
    else
      @user.update_attribute(:key, SecureRandom.urlsafe_base64)
      sign_in @user
      flash[:success] = "Veuillez changer immédiatement de mot de passe."
      redirect_to edit_user_path(@user)
    end
  end

  def recompute_scores
    User.all.each do |user|
      if !user.admin?
        point_attribution(user)
      end
    end
    redirect_to users_path
  end

  def notifications_new
    @notifications = Submission.order("updated_at DESC").paginate(page: params[:page]).all
    @new = true
    render :notifications
  end

  def notifications_update
    @notifications = current_user.sk.followed_submissions.order("updated_at DESC").paginate(page: params[:page]).all
    @new = false
    render :notifications
  end

  def notifs_show
    @notifs = current_user.sk.notifs.order("created_at")
    render :notifs
  end

  def take_skin
    @user = User.find(params[:user_id])
    if @user.admin?
      flash[:error] = "Pas autorisé..."
    else
      current_user.update_attribute(:skin, @user.id)
      sign_in current_user
      flash[:success] = "Vous êtes maintenant dans la peau de #{@user.name}."
    end
    redirect_to(:back)
  end

  def leave_skin
    if current_user.id == params[:user_id].to_i
      current_user.update_attribute(:skin, 0)
      sign_in current_user
      flash[:success] = "Vous êtes à nouveau dans votre peau."
    end
    redirect_to(:back)
  end

  private

  def signed_out_user
    if signed_in?
      redirect_to root_path
    end
  end
  def correct_user
    @user = User.find(params[:id])
    redirect_to root_path unless current_user.sk.id == @user.id
  end
  def admin_user
    redirect_to root_path unless current_user.sk.admin?
  end
  def root_user
    redirect_to root_path unless current_user.sk.root
  end
  def destroy_admin
    @user = User.find(params[:id])
    if @user.admin? && !current_user.sk.root
      flash[:error] = "One does not simply destroy an admin."
      redirect_to root_path
    end
  end

  def point_attribution(user)
    user.point.rating = 0
    partials = user.pointspersections
    partial = Array.new
    
    Section.all.each do |s|
      partial[s.id] = partials.where(:section_id => s.id).first
      if partial[s.id].nil?
        newpoint = Pointspersection.new
        newpoint.points = 0
        newpoint.section_id = s.id
        user.pointspersections << newpoint
        partial[s.id] = user.pointspersections.where(:section_id => s.id).first
      end
      partial[s.id].points = 0
    end

    user.solvedexercises.each do |e|
      if e.correct
        exo = e.exercise
        pt = exo.value

        if !exo.chapter.section.fondation? # Pas un fondement
          user.point.rating = user.point.rating + pt
        end

        partial[exo.chapter.section.id].points = partial[exo.chapter.section.id].points + pt
      end
    end

    user.solvedqcms.each do |q|
      if q.correct
        qcm = q.qcm
        pt = qcm.value

        if !qcm.chapter.section.fondation? # Pas un fondement
          user.point.rating = user.point.rating + pt
        end

        partial[qcm.chapter.section.id].points = partial[qcm.chapter.section.id].points + pt
      end
    end

    user.solvedproblems.each do |p|
      problem = p.problem
      pt = problem.value

      if !problem.section.fondation? # Pas un fondement
        user.point.rating = user.point.rating + pt
      end

      partial[problem.section.id].points = partial[problem.section.id].points + pt
    end

    user.point.save
    Section.all.each do |s|
      partial[s.id].save
    end

  end

end
