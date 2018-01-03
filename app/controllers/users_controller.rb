#encoding: utf-8

class UsersController < ApplicationController
  before_action :signed_in_user, only: [:destroy, :edit, :update, :create_administrator, :recompute_scores, :allsub, :allmysub, :notifs_show, :take_skin, :leave_skin, :unactivate, :reactivate, :switch_wepion, :switch_corrector, :change_group, :groups]
  before_action :correct_user, only: [:edit, :update]
  before_action :admin_user, only: [:take_skin, :unactivate, :reactivate, :switch_wepion, :change_group]
  before_action :corrector_user, only: [:allsub, :allmysub]
  before_action :root_user, only: [:create_administrator, :recompute_scores, :destroy, :switch_corrector, :validate_name]
  before_action :signed_out_user, only: [:new, :create, :password_forgotten]
  before_action :unactivate_admin, only: [:switchactivate]
  before_action :group_user, only: [:groups]

  # Index de tous les users avec scores
  def index
    if signed_in? && current_user.sk.root?
      oneweekago = Date.today - 7
      User.where("email_confirm = ? AND created_at < ?", false, oneweekago).each do |u|
        u.destroy
      end
    end
  end

  # S'inscrire au site : il faut être en ligne
  def new
    @user = User.new
  end

  # Modifier son compte : il faut être en ligne et que ce soit la bonne personne
  def edit
  end

  # S'inscrire au site 2 : il faut être hors ligne
  def create
    #@user = User.new(params[:user])
    @user = User.new(params.require(:user).permit(:first_name, :last_name, :seename, :email, :sex, :year, :country, :password, :password_confirmation))
    @user.key = SecureRandom.urlsafe_base64

    # Don't do email and captcha in development and tests
    @user.email_confirm = !Rails.env.production?

    if (not Rails.env.production? or verify_recaptcha(:model => @user, :message => "Captcha incorrect")) && @user.save
      UserMailer.registration_confirmation(@user.id).deliver if Rails.env.production?

      flash[:success] = "Vous allez recevoir un e-mail de confirmation d'ici quelques minutes pour activer votre compte. Vérifiez votre courrier indésirable si celui-ci semble ne pas arriver. Vous avez 7 jours pour confirmer votre inscription. Si vous rencontrez un problème, alors n'hésitez pas à contacter l'équipe Mathraining (voir 'Contact', en bas à droite de la page)."
      redirect_to root_path
    else
      render 'new'
    end
  end

  # Voir un utilisateur
  def show
    @user = User.find(params[:id])
  end

  def compare
    @user = []
    @user[1] = User.find(params[:id1])
    @user[2] = User.find(params[:id2])
  end

  # Modifier son compte 2 : il faut être en ligne et que ce soit la bonne personne
  def update
    if @user.update_attributes(params.require(:user).permit(:first_name, :last_name, :seename, :email, :sex, :year, :country, :password, :password_confirmation))
      flash[:success] = "Votre profil a bien été mis à jour. #{current_user.root?}"
      if(current_user.root? and current_user.other)
        @user.update_attribute(:valid_name, true)
        current_user.update_attribute(:skin, 0)
        redirect_to validate_name_path
      else
        redirect_to root_path
      end
    else
      render 'edit'
    end
  end

  # Supprimer un utilisateur : il faut être root
  def destroy
    @user = User.find(params[:id])
    if !@user.root?
      skinner = User.where(skin: @user.id)
      skinner.each do |s|
        s.update_attribute(:skin, 0)
      end
      @user.destroy
      flash[:success] = "Utilisateur supprimé."
    else
      flash[:danger] = "Il n'est pas possible de supprimer un root."
    end
    redirect_to users_path
  end

  # Rendre administrateur : il faut être root
  def create_administrator
    @user = User.find(params[:user_id])
    if @user.admin?
      flash[:danger] = "I see what you did here! Mais non ;-)"
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

  # Ajouter / Enlever du groupe Wépion
  def switch_wepion
    @user = User.find(params[:user_id])
    if !@user.admin?
      if @user.wepion
        flash[:success] = "Utilisateur retiré du groupe Wépion."
        @user.group = ""
        @user.save
      else
        flash[:success] = "Utilisateur ajouté au groupe Wépion."
      end
      @user.toggle!(:wepion)
    end
    redirect_to @user
  end

  # Ajouter / Enlever des correcteurs
  def switch_corrector
    @user = User.find(params[:user_id])
    if !@user.admin?
      if !@user.corrector
        flash[:success] = "Utilisateur ajouté aux correcteurs."
      else
        flash[:success] = "Utilisateur retiré des correcteurs."
      end
      @user.toggle!(:corrector)
    end
    redirect_to @user
  end

  # Changer de groupe
  def change_group
    @user = User.find(params[:user_id])
    g = params[:group]
    @user.group = g
    @user.save
    flash[:success] = "Utilisateur changé de groupe."
    redirect_to @user
  end

  # Activer son compte
  def activate
    @user = User.find(params[:id])
    if !@user.email_confirm && @user.key.to_s == params[:key].to_s
      @user.toggle!(:email_confirm)
      flash[:success] = "Votre compte a bien été activé! Veuillez maintenant vous connecter."
    elsif @user.key.to_s != params[:key].to_s
      flash[:danger] = "Le lien d'activation est erroné."
    else
      flash[:info] = "Ce compte est déjà actif!"
    end
    redirect_to root_path
  end

  # Mot de passe oublié
  def password_forgotten
    @user = User.where(:email => params[:user][:email]).first
    if @user
      if @user.email_confirm
        @user.update_attribute(:key, SecureRandom.urlsafe_base64)
        UserMailer.forgot_password(@user.id).deliver if Rails.env.production?
        flash[:success] = "Vous allez recevoir un e-mail d'ici quelques minutes pour que vous puissiez changer de mot de passe. Vérifiez votre courrier indésirable si celui-ci semble ne pas arriver."
      else
        flash[:danger] = "Veuillez d'abord confirmer votre adresse mail à l'aide du lien qui vous a été envoyé à l'inscription. Si vous n'avez pas reçu cet e-mail, alors n'hésitez pas à contacter l'équipe Mathraining (voir 'Contact', en bas à droite de la page)."
      end
    else
      flash[:danger] = "Aucun utilisateur ne possède cette adresse."
    end
    redirect_to root_path
  end

  # Mot de passe oublié 2
  def recup_password
    @user = User.find(params[:id])
    if @user.key.to_s != params[:key].to_s
      flash[:danger] = "Ce lien n'est pas correct."
      redirect_to root_path
    else
      @user.update_attribute(:key, SecureRandom.urlsafe_base64)
      if signed_in?
        sign_out
      end
      sign_in @user
      flash[:success] = "Veuillez changer immédiatement de mot de passe."
      redirect_to edit_user_path(@user)
    end
  end

  # Recalculer tous les scores
  def recompute_scores
    point_attribution_all
    Section.all.each do |s|
      s.max_score = 0
      if !s.fondation?
        s.problems.each do |p|
          if p.online?
            s.max_score = s.max_score + p.value
          end
        end
        s.chapters.each do |c|
          if c.online?
            c.exercises.each do |e|
              if e.online?
                s.max_score = s.max_score + e.value
              end
            end
            c.qcms.each do |q|
              if q.online?
                s.max_score = s.max_score + q.value
              end
            end
          end
        end
      end
      s.save
    end
    redirect_to users_path
  end

  # Voir toutes les soumissions (admin)
  def allsub
    @notifications = Submission.includes(:user, :problem, followings: :user).where(visible: true).order("lastcomment DESC").paginate(page: params[:page]).to_a
    @new = true
    render :allsub
  end

  # Voir les soumissions auxquelles on participe (admin)
  def allmysub
    @notifications = current_user.sk.followed_submissions.includes(:user, :problem).where("status > 0").order("lastcomment DESC").paginate(page: params[:page]).to_a
    @new = false
    render :allsub
  end
  
  # Voir toutes les nouvelles soumissions (admin)
  def allnewsub
    @notifications = Submission.includes(:user, :problem, followings: :user).where(status: 0, visible: true).order("created_at").to_a
    @new = true
    render :allnewsub
  end

  # Voir les nouveaux commentaires des soumissions auxquelles on participe (admin)
  def allmynewsub
    @notifications = current_user.sk.followed_submissions.includes(:user, :problem).order("lastcomment").to_a
    @notifications_other = Submission.includes(:user, :problem, followings: :user).where("status = 3").order("lastcomment").to_a
    @new = false
    render :allnewsub
  end

  # Voir les notifications (étudiant)
  def notifs_show
    @notifs = current_user.sk.notifs.order("created_at")
    render :notifs
  end

  # Prendre la peau d'un utilisateur
  def take_skin
    @user = User.find(params[:user_id])
    if @user.admin?
      flash[:danger] = "Pas autorisé..."
    else
      current_user.update_attribute(:skin, @user.id)
      flash[:success] = "Vous êtes maintenant dans la peau de #{@user.name}."
    end
    redirect_back(fallback_location: root_path)
  end

  # Quitter la peau d'un utilisateur
  def leave_skin
    if current_user.id == params[:user_id].to_i
      current_user.update_attribute(:skin, 0)
      flash[:success] = "Vous êtes à nouveau dans votre peau."
    end
    redirect_back(fallback_location: root_path)
  end

  # Désactiver / Réactiver un compte
  def switchactivate
    @user = User.find(params[:user_id])
    @user.toggle!(:active)
    redirect_to @user
  end

  def groups
  end

  def correctors
  end
  
  def validate_name
    u = User.where(:admin => false, :valid_name => false, :email_confirm => true).first
    if(!u.nil?)
      current_user.update_attribute(:skin, u.id)
      redirect_to edit_user_path(u)
    else
      current_user.update_attribute(:skin, 0)
      flash[:success] = "Aucun nom à valider!"
      redirect_to root_path
    end
  end

  ########## PARTIE PRIVEE ##########
  private

  # Vérifie qu'on est pas connecté
  def signed_out_user
    if signed_in?
      redirect_to root_path
    end
  end

  # Vérifie qu'il s'agit de la bonne personne
  def correct_user
    @user = User.find(params[:id])
    redirect_to root_path unless current_user.sk.id == @user.id
  end

  def corrector_user
    redirect_to root_path unless current_user.sk.admin or current_user.sk.corrector
  end

  def group_user
    redirect_to root_path unless current_user.sk.admin or current_user.sk.group != ""
  end

  # Vérifie qu'on ne désactive pas un admin
  def unactivate_admin
    @user = User.find(params[:user_id])
    if @user.admin? && !current_user.sk.root
      flash[:danger] = "Opération interdite envers les administrateurs."
      redirect_to root_path
    end
  end
end
