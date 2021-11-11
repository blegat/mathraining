#encoding: utf-8
class MyfilesController < ApplicationController
  before_action :signed_in_user, only: [:index, :show, :edit]
  before_action :signed_in_user_danger, only: [:download, :fake_delete, :update]
  before_action :get_myfile, only: [:show, :edit, :update, :download]
  before_action :get_myfile2, only: [:fake_delete]
  before_action :have_access, only: [:download]
  before_action :root_user, only: [:fake_delete, :edit, :update, :show, :index]

  # Télécharger le pièce jointe
  def download
    send_file @myfile.file.path, :type => @myfile.file_content_type, :filename => @myfile.file_file_name
  end
  
  def show
    type = @myfile.myfiletable_type
    about = @myfile.myfiletable
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
    elsif type == "Contestsolution"
      redirect_to contestproblem_path(about.contestproblem, :sol => about)
    elsif type == "Contestcorrection"
      redirect_to contestproblem_path(about.contestsolution.contestproblem, :sol => about.contestsolution)
    else
      redirect_to myfiles_path
    end
  end
  
  def edit
  end
  
  def update
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
    @fakething = @myfile.fake_del
    flash[:success] = "Contenu de la pièce jointe supprimé."

    if @fakething.fakefiletable_type == "Subject"
      @subject = @fakething.fakefiletable
      @q = 0
      @q = params[:q].to_i if params.has_key?:q
      redirect_to subject_path(@subject, :q => @q)
    elsif @fakething.fakefiletable_type == "Message"
      @message = @fakething.fakefiletable
      tot = @message.subject.messages.where("id <= ?", @message.id).count
      page = [0,((tot-1)/10).floor].max + 1
      @q = 0
      @q = params[:q].to_i if params.has_key?:q
      redirect_to subject_path(@message.subject, :anchor => @message.id, :page => page, :q => @q)
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

  # Voir toutes les pièces jointes
  def index
    @list = Myfile.order("file_file_size DESC").paginate(:page => params[:page], :per_page => 30)
  end

  ########## PARTIE PRIVEE ##########
  private
  
  def get_myfile
    @myfile = Myfile.find_by_id(params[:id])
    if @myfile.nil?
      render 'errors/access_refused' and return
    end
  end
  
  def get_myfile2
    @myfile = Myfile.find_by_id(params[:myfile_id])
    if @myfile.nil?
      render 'errors/access_refused' and return
    end
  end

  # Vérifie qu'on a accès à la pièce jointe
  def have_access
    type = @myfile.myfiletable_type
    if type == "Subject" || type == "Message"
      # Only admins and correctors can see corrector subjects - Only admins and wepion students can see wepion subjects
      subject = (type == "Subject" ? @myfile.myfiletable : @myfile.myfiletable.subject)
      redirect_to root_path if ((!current_user.sk.admin? && !current_user.sk.corrector?) && subject.admin) || ((!current_user.sk.admin? && !current_user.sk.wepion?) && subject.wepion)
    elsif type == "Tchatmessage"
      # Only roots and participants to the discussion
      tchatmessage = @myfile.myfiletable
      redirect_to root_path if (!current_user.sk.root? && !current_user.sk.discussions.include?(tchatmessage.discussion))
    elsif type == "Submission" || type == "Correction"
      # Only admins, submission user, correctors having solved the problem, and users having solved the problem (if submission is correct)
      submission = (type == "Submission" ? @myfile.myfiletable : @myfile.myfiletable.submission)
      redirect_to root_path unless (current_user.sk.admin? || current_user.sk == submission.user || current_user.sk.pb_solved?(submission.problem) && (current_user.sk.corrector? || submission.status == 2))
    elsif type == "Contestsolution" || type == "Contestcorrection"
      # Only organizers and solution user, or anybody if corrections are finished (status >= 4) and solution has 7
      # Only exception is that the solution user cannot see the correction if it is not published yet (status < 4)
      contestsolution = (type == "Contestsolution" ? @myfile.myfiletable : @myfile.myfiletable.contestsolution)
      contestproblem = contestsolution.contestproblem
      contest = contestproblem.contest
      redirect_to root_path unless (contest.is_organized_by_or_root(current_user) || contestsolution.user == current_user.sk || (contestproblem.status >= 4 && contestsolution.score == 7))
      redirect_to root_path if (type == "Contestcorrection" && contestsolution.user == current_user.sk && contestproblem.status < 4)
    end
  end

end
