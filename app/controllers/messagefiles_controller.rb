#encoding: utf-8
class MessagefilesController < ApplicationController
  before_filter :signed_in_user
  before_filter :have_access, only: [:download]
  before_filter :root_user, only: [:fake_delete]

  # Télécharger : il faut avoir l'accès
  def download
    send_file @thing.file.path, :type => @thing.file_content_type, :filename => @thing.file_file_name
  end
  
  # Supprimer fictivement : il faut être root
  def fake_delete
    @thing = Messagefile.find(params[:messagefile_id])
    @message = @thing.message
    @fakething = Fakemessagefile.new
    @fakething.message = @thing.message
    @fakething.file_file_name = @thing.file_file_name
    @fakething.file_content_type = @thing.file_content_type
    @fakething.file_file_size = @thing.file_file_size
    @fakething.file_updated_at = @thing.file_updated_at
    @fakething.save
    @thing.file.destroy
    @thing.destroy
    
    tot = @message.subject.messages.where("id <= ?", @message.id).count
    page = [0,((tot-1)/10).floor].max + 1
    
    q = 0
    if(params.has_key?:q)
      q = params[:q].to_i
    end

    flash[:success] = "Contenu de la pièce jointe supprimé."
    redirect_to subject_path(@message.subject, :anchor => @message.id, :page => page, :q => q)
  end
  
  ########## PARTIE PRIVEE ##########
  private
  
  # La seule façon de ne pas avoir accès est que le sujet soit admin et pas l'utilisateur
  def have_access
    @thing = Messagefile.find(params[:id])
    redirect_to root_path if (!current_user.sk.admin? && @thing.message.subject.admin)
  end

end
