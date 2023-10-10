class AddSubmissionPrerequisiteToChapters < ActiveRecord::Migration[7.0]
  def change
    add_column :chapters, :submission_prerequisite, :boolean, default: false
  end
end
