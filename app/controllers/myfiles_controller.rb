#encoding: utf-8
class MyfilesController < ApplicationController
  before_action :signed_in_user, only: [:index, :show]
  before_action :signed_in_user_danger, only: [:fake_delete]
  before_action :root_user, only: [:fake_delete, :show, :index]
  
  before_action :get_myfile, only: [:show]
  before_action :get_myfile2, only: [:fake_delete]
  
  # Show all the files
  def index
    @list = Myfile.order("id DESC").paginate(:page => params[:page], :per_page => 30).includes(file_attachment: :blob).includes(:myfiletable)
  end
  
  # Show one file (redirect to somewhere depending on the context)
  def show
    type = @myfile.myfiletable_type
    about = @myfile.myfiletable
    if type == "Submission"
      redirect_to problem_path(about.problem, :sub => about)
    elsif type == "Correction"
      redirect_to problem_path(about.submission.problem, :sub => about.submission)
    elsif type == "Message"
      redirect_to subject_path(about.subject, :page => about.page, :msg => about.id)
    elsif type == "Contestsolution"
      redirect_to contestproblem_path(about.contestproblem, :sol => about)
    elsif type == "Contestcorrection"
      redirect_to contestproblem_path(about.contestsolution.contestproblem, :sol => about.contestsolution)
    elsif type == "Tchatmessage"
      redirect_to myfiles_path
    end
  end

  # Delete fictively a file (replacing it with a fake file)
  def fake_delete
    @fakething = @myfile.fake_del
    flash[:success] = "Contenu de la pièce jointe supprimé."

    if @fakething.fakefiletable_type == "Message"
      @message = @fakething.fakefiletable
      @q = "all"
      @q = params[:q] if params.has_key?:q
      redirect_to subject_path(@message.subject, :page => @message.page, :msg => @message.id, :q => @q)
    elsif @fakething.fakefiletable_type == "Tchatmessage"
      redirect_to myfiles_path
    elsif @fakething.fakefiletable_type == "Submission"
      @submission = @fakething.fakefiletable
      redirect_to problem_path(@submission.problem, :sub => @submission)
    elsif @fakething.fakefiletable_type == "Correction"
      @submission = @fakething.fakefiletable.submission
      redirect_to problem_path(@submission.problem, :sub => @submission)
    elsif @fakething.fakefiletable_type == "Contestsolution"
      @contestsolution = @fakething.fakefiletable
      redirect_to contestproblem_path(@contestsolution.contestproblem, :sol => @contestsolution)
    elsif @fakething.fakefiletable_type == "Contestcorrection"
      @contestsolution = @fakething.fakefiletable.contestsolution
      redirect_to contestproblem_path(@contestsolution.contestproblem, :sol => @contestsolution)
    end
  end

  private
  
  ########## GET METHODS ##########
  
  # Get the file
  def get_myfile
    @myfile = Myfile.find_by_id(params[:id])
    return if check_nil_object(@myfile)
  end
  
  # Get the file (v2)
  def get_myfile2
    @myfile = Myfile.find_by_id(params[:myfile_id])
    return if check_nil_object(@myfile)
  end

end
