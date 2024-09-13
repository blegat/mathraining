#encoding: utf-8
class PrivacypoliciesController < ApplicationController
  before_action :signed_in_user, only: [:index, :edit, :edit_description]
  before_action :signed_in_user_danger, only: [:new, :update, :destroy, :put_online]
  before_action :root_user, only: [:index, :new, :edit, :update, :destroy, :put_online]
  
  before_action :get_policy, only: [:show, :edit, :update, :destroy]
  before_action :get_policy2, only: [:edit_description, :put_online]
  
  before_action :is_offline, only: [:edit, :destroy, :put_online]
  before_action :is_online, only: [:show]
  
  # Show all privacy policies
  def index
  end

  # Show the last privacy policy
  def last_policy
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

  # Update a privacy policy or its description (send the form)
  def update
    if @privacypolicy.update(params.require(:privacypolicy).permit(:description, :content))
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
  
  # Get the privacy policy (v2)
  def get_policy2
    @privacypolicy = Privacypolicy.find_by_id(params[:privacypolicy_id])
    return if check_nil_object(@privacypolicy)
  end
  
  ########## CHECK METHODS ##########
  
  # Check that the privacy policy is offline
  def is_offline
    return if check_online_object(@privacypolicy)
  end
  
  # Check that the privacy policy is online
  def is_online
    return if check_offline_object(@privacypolicy)
  end
end
