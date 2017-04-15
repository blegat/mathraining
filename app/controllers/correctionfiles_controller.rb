#encoding: utf-8
class CorrectionfilesController < ApplicationController
  before_action :signed_in_user
  before_action :have_access, only: [:download]
  before_action :root_user, only: [:fake_delete]

  # Télécharger pièce jointe : vérifier qu'on est en ligne et qu'on a accès
  def download
    send_file @thing.file.path, :type => @thing.file_content_type, :filename => @thing.file_file_name
  end

  # Supprimer fictivement la pièce jointe : il faut être root
  def fake_delete
    @thing = Correctionfile.find(params[:correctionfile_id])
    @submission = @thing.correction.submission
    @fakething = Fakecorrectionfile.new
    @fakething.correction = @thing.correction
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

  ########## PARTIE PRIVEE ##########
  private

  # Pour avoir accès, il faut soit être admin, soit être le propriétaire de la pièce jointe, soit avoir résolu le même problème
  def have_access
    @thing = Correctionfile.find(params[:id])
    redirect_to root_path unless (current_user.sk.admin? || current_user.sk == @thing.correction.submission.user || current_user.sk.pb_solved?(@thing.correction.submission.problem))
  end

end
