#encoding: utf-8
class PrivacypoliciesController < ApplicationController
  skip_before_action :user_has_some_actions_to_take
  
  before_action :signed_in_user, only: [:index, :edit, :edit_description]
  before_action :signed_in_user_danger, only: [:new, :update, :update_description, :destroy, :put_online]
  before_action :root_user, only: [:index, :new, :edit, :update, :edit_description, :update_description, :destroy, :put_online]
  
  before_action :get_policy, only: [:show, :edit, :update, :destroy, :edit_description, :update_description, :put_online]
  
  before_action :offline_privacypolicy, only: [:edit, :update, :destroy, :put_online]
  before_action :online_privacypolicy, only: [:show]
  
  # Show all privacy policies
  def index
  end

  # Show the last privacy policy
  def last
    @last_policy = Privacypolicy.where(:online => true).order(:publication_time).last
    if @last_policy.nil?
      flash[:danger] = "Le site n'a actuellement aucune politique de confidentalité."
      redirect_to root_path
    else
      redirect_to @last_policy
    end
  end
  
  # Show one privacy policy
  def show
  end

  # Create a privacy policy (automatic from the last one)
  def new
    last_policy = Privacypolicy.where(:online => true).order(:publication_time).last
    Privacypolicy.create(:publication_time => DateTime.now, :online => false, :description => "- À écrire -", :content => (!last_policy.nil? ? last_policy.content : "- À écrire -"))
    redirect_to privacypolicies_path
  end

  # Update a privacy policy (show the form)
  def edit
  end
  
  # Update the description of a privacy policy (show the form)
  def edit_description
  end

  # Update a privacy policy (send the form)
  def update
    if @privacypolicy.update(params.require(:privacypolicy).permit(:content))
      flash[:success] = "Modification enregistrée."
      redirect_to privacypolicies_path
    else
      render 'edit'
    end
  end
  
  # Update the description of a privacy policy (send the form)
  def update_description
    if @privacypolicy.update(params.require(:privacypolicy).permit(:description))
      flash[:success] = "Modification enregistrée."
      redirect_to privacypolicies_path
    else
      render 'edit_description'
    end
  end
  
  # Delete a privacy policy
  def destroy
    @privacypolicy.destroy
    flash[:success] = "Politique de confidentialité supprimée."
    redirect_to privacypolicies_path
  end

  # Put a privacy policy online
  def put_online
    @privacypolicy.update(:online           => true,
                          :publication_time => DateTime.now)
    User.all.update_all(:last_policy_read => false)
    redirect_to @privacypolicy
  end

  private
  
  ########## GET METHODS ##########
  
  # Get the privacy policy
  def get_policy
    @privacypolicy = Privacypolicy.find_by_id(params[:id])
    return if check_nil_object(@privacypolicy)
  end
  
  ########## CHECK METHODS ##########
  
  # Check that the privacy policy is offline
  def offline_privacypolicy
    return if check_online_object(@privacypolicy)
  end
  
  # Check that the privacy policy is online
  def online_privacypolicy
    return if check_offline_object(@privacypolicy)
  end
end
