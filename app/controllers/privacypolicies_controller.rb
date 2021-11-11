#encoding: utf-8
class PrivacypoliciesController < ApplicationController
  before_action :signed_in_user, only: [:index, :edit, :edit_description]
  before_action :signed_in_user_danger, only: [:new, :update, :update_description, :destroy, :put_online]
  before_action :root_user, only: [:index, :new, :edit, :update, :destroy, :put_online]
  before_action :get_policy, only: [:show, :edit, :update, :destroy]
  before_action :get_policy2, only: [:edit_description, :put_online]
  before_action :is_offline, only: [:edit, :destroy, :put_online]
  before_action :is_online, only: [:show]
  
  def index
  end

  # Voir la dernière politique de confidentialité
  def last_policy
    @last_policy = Privacypolicy.where(:online => true).order(:publication).last
    if @last_policy.nil?
      flash[:danger] = "Le site n'a actuellement aucune politique de confidentalité."
      redirect_to root_path
    else
      redirect_to @last_policy
    end
  end
  
  # Voir une version de la politique de confidentialité
  def show
  end

  # Créer une politique de confidentialité
  def new
    @privacypolicy = Privacypolicy.new
    @privacypolicy.publication = DateTime.now
    @privacypolicy.online = false
    @privacypolicy.description = " - À écrire - "
    @last_policy = Privacypolicy.where(:online => true).order(:publication).last
    if !@last_policy.nil?
      @privacypolicy.content = @last_policy.content
    else
      @privacypolicy.content = @privacypolicy.description
    end
    @privacypolicy.save
    redirect_to privacypolicies_path
  end

  # Editer une politique de confidentialité : doit être hors ligne
  def edit
  end
  
  # Editer la description d'une politique de confidentialité (peut être en ligne)
  def edit_description
  end

  # Editer une politique de confidentialité 2 : soit le contenu soit la description
  def update
    if @privacypolicy.update_attributes(params.require(:privacypolicy).permit(:description, :content))
      flash[:success] = "Modification enregistrée."
      redirect_to privacypolicies_path
    else
      if params[:privacypolicy][:description].nil?
        render 'edit'
      else
        render 'edit_description'
      end
    end
  end
  
  # Supprimer une politique de confidentialité : doit être hors-ligne
  def destroy
    @privacypolicy.destroy
    flash[:success] = "Politique de confidentialité supprimée."
    redirect_to privacypolicies_path
  end

  # Mettre en ligne : doit être hors-ligne
  def put_online
    @privacypolicy.online = true
    @privacypolicy.publication = DateTime.now
    @privacypolicy.save
    User.all.each do |u|
      u.last_policy_read = false
      u.save
    end
    redirect_to @privacypolicy
  end

  ########## PARTIE PRIVEE ##########
  private
  
  def get_policy
    @privacypolicy = Privacypolicy.find_by_id(params[:id])
    if @privacypolicy.nil?
      render 'errors/access_refused' and return
    end
  end
  
  def get_policy2
    @privacypolicy = Privacypolicy.find_by_id(params[:privacypolicy_id])
    if @privacypolicy.nil?
      render 'errors/access_refused' and return
    end
  end
  
  # Vérifie que la politique de confidentialité est hors-ligne
  def is_offline
    if @privacypolicy.online
      render 'errors/access_refused' and return
    end
  end
  
  # Vérifie que la politique de confidentialité est en ligne
  def is_online
    if !@privacypolicy.online
      render 'errors/access_refused' and return
    end
  end
end
