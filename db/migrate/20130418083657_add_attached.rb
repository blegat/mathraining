class AddAttached < ActiveRecord::Migration[5.0]
  def change
    create_table :submissionfiles do |t|
      t.references :submission
    end
    add_attachment :submissionfiles, :file
    
    create_table :correctionfiles do |t|
      t.references :correction
    end
    add_attachment :correctionfiles, :file
    
    create_table :subjectfiles do |t|
      t.references :subject
    end
    add_attachment :subjectfiles, :file
    
    create_table :messagefiles do |t|
      t.references :message
    end
    add_attachment :messagefiles, :file
  end
end
