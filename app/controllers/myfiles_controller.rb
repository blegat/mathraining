#encoding: utf-8
class MyfilesController < ApplicationController
  before_action :signed_in_user, only: [:index, :show, :edit]
  before_action :signed_in_user_danger, only: [:download, :fake_delete, :update]
  before_action :have_access, only: [:download]
  before_action :root_user, only: [:fake_delete, :edit, :update, :show, :index]

  # Télécharger le pièce jointe
  def download
    send_file @thing.file.path, :type => @thing.file_content_type, :filename => @thing.file_file_name
  end
  
  def show
    f = Myfile.find(params[:id])
    type = f.myfiletable_type
    about = f.myfiletable
    if type == "Submission"
      redirect_to problem_path(about.problem, :sub => about)
    elsif type == "Correction"
      redirect_to problem_path(about.submission.problem, :sub => about.submission)
    elsif type == "Subject"
      redirect_to about
    elsif type == "Message"
      tot = about.subject.messages.where("id <= ?", about.id).count
      page = [0,((tot-1)/10).floor].max + 1
      redirect_to subject_path(about.subject, :page => page, :message => about.id)
    else
      redirect_to myfiles_path
    end
  end
  
  def edit
    @myfile = Myfile.find(params[:id])
  end
  
  def update
    @myfile = Myfile.find(params[:id])
    if !params["file"].nil?
      if(@myfile.update_attributes(file: params["file".to_sym]))
        flash[:success] = "C'est remplacé !"
      else
      flash[:danger] = "Une condition n'est pas respectée..."
      end
    else
      flash[:danger] = "Pièce jointe vide."
    end
    redirect_to edit_myfile_path(@myfile)
  end

  # Supprimer la pièce jointe fictivement
  def fake_delete
    @thing = Myfile.find(params[:myfile_id])
    @fakething = @thing.fake_del()

    if @fakething.fakefiletable_type == "Subject"
      @subject = @fakething.fakefiletable
      @q = 0
      @q = params[:q].to_i if params.has_key?:q
      flash[:success] = "Contenu de la pièce jointe supprimé."
      redirect_to subject_path(@subject, :q => @q)
    elsif @fakething.fakefiletable_type == "Message"
      @message = @fakething.fakefiletable
      tot = @message.subject.messages.where("id <= ?", @message.id).count
      page = [0,((tot-1)/10).floor].max + 1
      @q = 0
      @q = params[:q].to_i if params.has_key?:q
      flash[:success] = "Contenu de la pièce jointe supprimé."
      redirect_to subject_path(@message.subject, :anchor => @message.id, :page => page, :q => @q)
    elsif @fakething.fakefiletable_type == "Tchatmessage"
      flash[:success] = "Contenu de la pièce jointe supprimé."
      redirect_to pieces_jointes_path
    elsif @fakething.fakefiletable_type == "Submission"
      @submission = @fakething.fakefiletable
      flash[:success] = "Contenu de la pièce jointe supprimé."
      redirect_to problem_path(@submission.problem, :sub => @submission)
    elsif @fakething.fakefiletable_type == "Correction"
      @submission = @fakething.fakefiletable.submission
      flash[:success] = "Contenu de la pièce jointe supprimé."
      redirect_to problem_path(@submission.problem, :sub => @submission)
    end
  end

  # Voir toutes les pièces jointes
  def index
    @list = Myfile.order("file_file_size DESC").paginate(:page => params[:page], :per_page => 30)
  end

  ########## PARTIE PRIVEE ##########
  private

  # Vérifie qu'on a accès à la pièce jointe (CHANGE !)
  def have_access
    @thing = Myfile.find(params[:id])
    if @thing.myfiletable_type == "Subject"
      redirect_to root_path if (!current_user.sk.admin? && @thing.myfiletable.admin)
    elsif @thing.myfiletable_type == "Message"
      redirect_to root_path if (!current_user.sk.admin? && @thing.myfiletable.subject.admin)
    elsif @thing.myfiletable_type == "Tchatmessage"
      redirect_to root_path if (!current_user.sk.admin? && !current_user.sk.discussions.include?(@thing.myfiletable.discussion))
    elsif @thing.myfiletable_type == "Submission"
      redirect_to root_path unless (current_user.sk.admin? || current_user.sk == @thing.myfiletable.user || current_user.sk.pb_solved?(@thing.myfiletable.problem))
    elsif @thing.myfiletable_type == "Correction"
      redirect_to root_path unless (current_user.sk.admin? || current_user.sk == @thing.myfiletable.submission.user || current_user.sk.pb_solved?(@thing.myfiletable.submission.problem))
    end
  end

end
