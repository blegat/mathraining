#encoding: utf-8
class SubmissionfilesController < ApplicationController
  before_action :signed_in_user
  before_action :have_access, only: [:download]
  before_action :root_user, only: [:fake_delete, :seeall]

  # Télécharger la pièce jointe
  def download
    send_file @thing.file.path, :type => @thing.file_content_type, :filename => @thing.file_file_name
  end

  # Supprimer fictivement la pièce jointe
  def fake_delete
    @thing = Submissionfile.find(params[:submissionfile_id])

    @submission = @thing.submission
    @fakething = Fakesubmissionfile.new
    @fakething.submission = @thing.submission
    @fakething.file_file_name = @thing.file_file_name
    @fakething.file_content_type = @thing.file_content_type
    @fakething.file_file_size = @thing.file_file_size
    @fakething.file_updated_at = @thing.file_updated_at
    @fakething.save
    @thing.file.destroy
    @thing.destroy

    flash[:success] = "Contenu de la pièce jointe supprimé."
    redirect_to problem_path(@submission.problem, :sub => @submission)
  end

  # Voir toutes les pièces jointes
  def seeall
    @list = Array.new

    Submissionfile.all.each do |f|
      @list.push([f.file_updated_at, 1, f])
    end

    Fakesubmissionfile.all.each do |f|
      @list.push([f.file_updated_at, 2, f])
    end

    Correctionfile.all.each do |f|
      @list.push([f.file_updated_at, 3, f])
    end

    Fakecorrectionfile.all.each do |f|
      @list.push([f.file_updated_at, 4, f])
    end

    Subjectfile.all.each do |f|
      @list.push([f.file_updated_at, 5, f])
    end

    Fakesubjectfile.all.each do |f|
      @list.push([f.file_updated_at, 6, f])
    end

    Messagefile.all.each do |f|
      @list.push([f.file_updated_at, 7, f])
    end

    Fakemessagefile.all.each do |f|
      @list.push([f.file_updated_at, 8, f])
    end

    Tchatmessagefile.all.each do |f|
      @list.push([f.file_updated_at, 9, f])
    end

    Faketchatmessagefile.all.each do |f|
      @list.push([f.file_updated_at, 10, f])
    end

    @list = @list.sort_by{|a| -a[0].min - 60 * a[0].hour - 3600*a[0].day - 3600*32*a[0].month - 3600*32*12*a[0].year}
  end

  ########## PARTIE PRIVEE ##########
  private

  # Vérifie qu'on a accès à cette pièce jointe
  def have_access
    @thing = Submissionfile.find(params[:id])
    redirect_to root_path unless (current_user.sk.admin? || current_user.sk == @thing.submission.user || current_user.sk.pb_solved?(@thing.submission.problem))
  end

end
