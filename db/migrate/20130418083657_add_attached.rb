class AddAttached < ActiveRecord::Migration[5.0]
  def change
    create_table :submissionfiles do |t|
      t.references :submission
    end
    add_attachment :submissionfiles, :file
    add_index :submissionfiles, :submission_id
    
    create_table :correctionfiles do |t|
      t.references :correction
    end
    add_attachment :correctionfiles, :file
    
    add_index :correctionfiles, :correction_id
    
    create_table :subjectfiles do |t|
      t.references :subject
    end
    add_attachment :subjectfiles, :file
    
    add_index :subjectfiles, :subject_id
    
    create_table :messagefiles do |t|
      t.references :message
    end
    add_attachment :messagefiles, :file
    
    add_index :messagefiles, :message_id
  end
end
