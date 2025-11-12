#encoding: utf-8

module FileConcern
  extend ActiveSupport::Concern
  
  protected
  
  # Method called from several locations to create files from a form
  def create_files
    # Add new files to 'attach'
    attach = Array.new
    totalsize = add_new_files(attach)
    destroy_files(attach) and return [] if !@file_error.nil?
    
    # Check total size of files
    check_files_total_size(totalsize)
    destroy_files(attach) and return [] if !@file_error.nil?
    
    # Return 'attach': one should call attach_files(attach, object) after having saved the object
    return attach
  end

  # Method called from several locations to update files from a form: we should be sure that the object is valid
  def update_files(object)
    # Compute total size of checked existing files
    totalsize = 0
    postfix = (params["postfix"].nil? ? "" : params["postfix"]);
    object.myfiles.each do |f|
      if !params["prevFile#{postfix}_#{f.id}".to_sym].nil?
        totalsize = totalsize + f.file.blob.byte_size
      end
    end
    
    # Add new files to 'attach'
    attach = Array.new
    totalsize += add_new_files(attach)
    destroy_files(attach) and return if !@file_error.nil?
    
    # Check total size of files
    check_files_total_size(totalsize)
    destroy_files(attach) and return if !@file_error.nil?
    
    # Delete unchecked files (only at the end if there is no error with other files)
    object.myfiles.each do |f|
      if params["prevFile#{postfix}_#{f.id}".to_sym].nil?
        f.destroy # Should automatically purge the file
      end
    end
    object.fakefiles.each do |f|
      if params["prevFakeFile#{postfix}_#{f.id}".to_sym].nil?
        f.destroy
      end
    end
    
    # Actually attach the files to the object
    attach_files(attach, object)
  end
  
  # Helper method called by create_files and update_files to create all new files
  def add_new_files(attach)
    totalsize = 0
    k = 1
    postfix = (params["postfix"].nil? ? "" : params["postfix"]);
    while !params["hidden#{postfix}_#{k}".to_sym].nil? do
      if !params["file#{postfix}_#{k}".to_sym].nil?
        attach.push(Myfile.new(:file => params["file#{postfix}_#{k}".to_sym]))
        if !attach.last.save
          attach.pop()
          nom = params["file#{postfix}_#{k}".to_sym].original_filename
          @file_error = "Votre pièce jointe '#{nom}' ne respecte pas les conditions."
          return 0;
        end
        totalsize = totalsize + attach.last.file.blob.byte_size
      end
      k = k+1
    end
    
    return totalsize
  end
  
  # Helper method called by create_files and update_files to check maximum total size of files
  def check_files_total_size(totalsize)
    limit = (Rails.env.test? ? 15.kilobytes : 5.megabytes) # In test mode we put a very small limit
    limit_str = (Rails.env.test? ? "15 ko" : "5 Mo")
    if totalsize > limit
      @file_error = "Vos pièces jointes font plus de #{limit_str} au total (#{(totalsize.to_f/1.megabyte).round(3)} Mo)"
    end
  end
  
  # Method called from several locations to attach the uploaded files to an object
  def attach_files(attach, object)
    attach.each do |a|
      a.update_attribute(:myfiletable, object)
    end
  end

  # Method called from several locations to delete some temporarily uploaded files (because of another error)
  def destroy_files(attach)
    attach.each do |a|
      a.destroy # Should automatically purge the file
    end
  end
end
