#encoding: utf-8
class SubjectfilesController < ApplicationController
  before_action :signed_in_user
  before_action :have_access, only: [:download]
  before_action :root_user, only: [:fake_delete]

  # Télécharger le pièce jointe
  def download
    send_file @thing.file.path, :type => @thing.file_content_type, :filename => @thing.file_file_name
  end
  
  # Supprimer la pièce jointe fictivement
  def fake_delete
  	@thing = Subjectfile.find(params[:subjectfile_id])
    @subject = @thing.subject
    @fakething = Fakesubjectfile.new
    @fakething.subject = @thing.subject
    @fakething.file_file_name = @thing.file_file_name
    @fakething.file_content_type = @thing.file_content_type
    @fakething.file_file_size = @thing.file_file_size
    @fakething.file_updated_at = @thing.file_updated_at
    @fakething.save
    @thing.file.destroy
    @thing.destroy
    
    q = 0
    if(params.has_key?:q)
      q = params[:q].to_i
    end
    
    flash[:success] = "Contenu de la pièce jointe supprimé."
    redirect_to subject_path(@subject, :q => q)
  end

  ########## PARTIE PRIVEE ##########
  private

  # Vérifie qu'on a accès à la pièce jointe
  def have_access
    @thing = Subjectfile.find(params[:id])
    redirect_to root_path if (!current_user.sk.admin? && @thing.subject.admin)
  end
  
end
