#encoding: utf-8
class MyfilesController < ApplicationController
  before_action :signed_in_user, only: [:seeall]
  before_action :signed_in_user_danger, only: [:download, :fake_delete, :edit, :update]
  before_action :have_access, only: [:download]
  before_action :root_user, only: [:fake_delete, :edit, :update]

  # Télécharger le pièce jointe
  def download
    send_file @thing.file.path, :type => @thing.file_content_type, :filename => @thing.file_file_name
  end
  
  def edit
    @myfile = Myfile.find(params[:id])
  end
  
  def update
    @myfile = Myfile.find(params[:id])
    if !params["file"].nil?
      d = @myfile.file_updated_at
      if(@myfile.update_attributes(file: params["file".to_sym]))
        @myfile.file_updated_at = d
        @myfile.save
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
    @fakething = Fakefile.new
    @fakething.fakefiletable_type = @thing.myfiletable_type
    @fakething.fakefiletable_id = @thing.myfiletable_id
    @fakething.file_file_name = @thing.file_file_name
    @fakething.file_content_type = @thing.file_content_type
    @fakething.file_file_size = @thing.file_file_size
    @fakething.file_updated_at = @thing.file_updated_at
    @fakething.save
    @thing.file.destroy
    @thing.destroy

    if @fakething.fakefiletable_type == "Subject"
      @subject = @fakething.fakefiletable
      q = 0
      if(params.has_key?:q)
        q = params[:q].to_i
      end

      flash[:success] = "Contenu de la pièce jointe supprimé."
      redirect_to subject_path(@subject, :q => q)
    elsif @fakething.fakefiletable_type == "Message"
      @message = @fakething.fakefiletable
      tot = @message.subject.messages.where("id <= ?", @message.id).count
      page = [0,((tot-1)/10).floor].max + 1

      q = 0
      if(params.has_key?:q)
        q = params[:q].to_i
      end

      flash[:success] = "Contenu de la pièce jointe supprimé."
      redirect_to subject_path(@message.subject, :anchor => @message.id, :page => page, :q => q)
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
  def seeall
    @list = Array.new

    Myfile.all.each do |f|
      @list.push([f.file_updated_at, true, f])
    end

    Fakefile.all.each do |f|
      @list.push([f.file_updated_at, false, f])
    end

    @list = @list.sort_by{|a| -a[0].min - 60 * a[0].hour - 3600*a[0].day - 3600*32*a[0].month - 3600*32*12*a[0].year}
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
