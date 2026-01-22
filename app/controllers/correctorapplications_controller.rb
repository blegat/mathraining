#encoding: utf-8
class CorrectorapplicationsController < ApplicationController
  before_action :signed_in_user, only: [:index, :show]
  before_action :signed_in_user_danger, only: [:create, :destroy, :answer]
  before_action :root_user, only: [:index, :show, :destroy, :answer]
  
  before_action :get_correctorapplication, only: [:show, :destroy, :answer]
  
  before_action :can_send_application, only: [:create]
  
  # Show all applications (for root)
  def index
    processed = (params.has_key?(:show_old))
    @correctorapplications = Correctorapplication.includes(:user).where(:processed => processed).order("created_at DESC").paginate(:page => params[:page], :per_page => 50)
  end
  
  # Show one application (for root)
  def show
    if !@correctorapplication.processed?
      @tchatmessage = Tchatmessage.new
    end
  end

  # Send an application (show the form)
  def new
    @correctorapplication = Correctorapplication.new(:user => current_user)
  end
  
  # Send an application (send the form)
  def create
    @correctorapplication = Correctorapplication.new(params.require(:correctorapplication).permit(:content))
    @correctorapplication.user = current_user
    if @correctorapplication.save
      flash[:success] = "Votre candidature a bien été envoyée."
      redirect_to new_correctorapplication_path
    else
      render 'new'
    end
  end

  # Delete an application
  def destroy
    @correctorapplication.destroy
    flash[:success] = "Candidature supprimée."
    redirect_to correctorapplications_path
  end
  
  # Answer to application (and mark as processed)
  def answer
    @tchatmessage = Discussion.send_message_from_to(current_user, @correctorapplication.user, params[:correctorapplication][:answer], @correctorapplication)
    if @tchatmessage.new_record? # Means that it was not saved correctly
      render 'show' and return
    end
    @correctorapplication.update(:processed => true, :tchatmessage => @tchatmessage)
    reminder_content = "[u]Rappel de la candidature[/u] :\n\n" + @correctorapplication.content
    reminder_tchatmessage = Discussion.send_message_from_to(current_user, @correctorapplication.user, reminder_content)
    reminder_tchatmessage.update_attribute(:created_at, @tchatmessage.created_at - 1.second) # To make it appear below the other one
    flash[:success] = "Votre réponse a bien été envoyée."
    redirect_to @correctorapplication
  end
  
  private
  
  ########## GET METHODS ##########
  
  # Get the application
  def get_correctorapplication
    @correctorapplication = Correctorapplication.find_by_id(params[:id])
    return if check_nil_object(@correctorapplication)
  end
  
  ########## CHECK METHODS ##########
  
  # Check that current user is not already corrector/admin and that it has enough points
  def can_send_application
    if current_user.admin? || current_user.corrector? || current_user.rating < (Rails.env.development? ? 500 : 5000)
      render 'errors/access_refused'
    end
  end
end
