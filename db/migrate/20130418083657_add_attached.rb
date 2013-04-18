class AddAttached < ActiveRecord::Migration
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
  end
end
