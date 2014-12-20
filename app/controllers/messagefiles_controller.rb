#encoding: utf-8
class MessagefilesController < ApplicationController
  before_filter :have_access, only: [:download]
  before_filter :check_root, only: [:fake_delete]

  def download
    send_file @thing.file.path, :type => @thing.file_content_type, :filename => @thing.file_file_name
  end
  
  def fake_delete
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

  private

  def have_access
    @thing = Messagefile.find(params[:id])
    redirect_to root_path if ((!signed_in? || !current_user.sk.admin?) && @thing.message.subject.admin)
  end
  
  def check_root
    @thing = Messagefile.find(params[:messagefile_id])
    redirect_to root_path unless current_user.sk.root?
  end

end
