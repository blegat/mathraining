class AddAttached < ActiveRecord::Migration
  def change
    create_table :submissionfiles do |t|
      t.references :submission
    end
    add_attachment :submissionfiles, :file
    add_index :submissionfiles, :submission_id
  end
end
