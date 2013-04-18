#encoding: utf-8
class CorrectionfilesController < ApplicationController
  before_filter :signed_in_user
  before_filter :have_access
  
  def download
    send_file @thing.file.path, :type => @thing.file_content_type, :filename => @thing.file_file_name
  end
  
  private
  
  def have_access
    @thing = Correctionfile.find(params[:id])
    redirect_to root_path unless (current_user.admin? || current_user == @thing.correction.submission.user)
  end
  
end
