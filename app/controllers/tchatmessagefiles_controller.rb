#encoding: utf-8
class TchatmessagefilesController < ApplicationController
  before_filter :signed_in_user
  before_filter :have_access, only: [:download]
  before_filter :root_user, only: [:fake_delete]

  # Télécharger : il faut avoir l'accès
  def download
    send_file @thing.file.path, :type => @thing.file_content_type, :filename => @thing.file_file_name
  end

  # Supprimer fictivement : il faut être root
  def fake_delete
    @thing = Tchatmessagefile.find(params[:tchatmessagefile_id])
    @tchatmessage = @thing.tchatmessage
    @fakething = Faketchatmessagefile.new
    @fakething.tchatmessage = @thing.tchatmessage
    @fakething.file_file_name = @thing.file_file_name
    @fakething.file_content_type = @thing.file_content_type
    @fakething.file_file_size = @thing.file_file_size
    @fakething.file_updated_at = @thing.file_updated_at
    @fakething.save
    @thing.file.destroy
    @thing.destroy

    flash[:success] = "Contenu de la pièce jointe supprimé."
    redirect_to pieces_jointes_path
  end

  ########## PARTIE PRIVEE ##########
  private

  # La seule façon de ne pas avoir accès est que le sujet soit admin et pas l'utilisateur
  def have_access
    @thing = Tchatmessagefile.find(params[:id])
    redirect_to root_path if (!current_user.sk.admin? && !current_user.sk.discussions.include?(@thing.tchatmessage.discussion))
  end

end
