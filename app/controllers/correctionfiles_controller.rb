#encoding: utf-8
class CorrectionfilesController < ApplicationController
  before_filter :signed_in_user
  before_filter :have_access, only: [:download]
  before_filter :check_root, only: [:fake_delete]

  def download
    send_file @thing.file.path, :type => @thing.file_content_type, :filename => @thing.file_file_name
  end
  
  def fake_delete
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
    
    redirect_to problem_path(@submission.problem, :sub => @submission),
            flash: { success: "Contenu de la pièce jointe supprimé." }
  end

  private

  def have_access
    @thing = Correctionfile.find(params[:id])
    redirect_to root_path unless (current_user.sk.admin? || current_user.sk == @thing.correction.submission.user || current_user.sk.solved?(@thing.correction.submission.problem))
  end
  
  def check_root
    @thing = Correctionfile.find(params[:correctionfile_id])
    redirect_to root_path unless current_user.sk.root?
  end

end
