class AddOldCreatedAtToSubmissions < ActiveRecord::Migration[7.1]
  def change
    if reverting?
      Submission.update_all("created_at=old_created_at")
    end
  
    add_column :submissions, :old_created_at, :datetime, :precision => nil
    
    unless reverting?
      Submission.update_all("old_created_at=created_at")
    end
  end
end
