class CreateProblemSubmissions < ActiveRecord::Migration
  def change
    create_table :problem_submissions do |t|
      t.references :problem
      t.references :user
      t.text :content

      t.timestamps
    end
    add_index :problem_submissions, [:problem_id, :user_id]
  end
end
