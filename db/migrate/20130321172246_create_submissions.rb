class CreateSubmissions < ActiveRecord::Migration
  def change
    create_table :submissions do |t|
      t.references :problem
      t.references :user
      t.text :content

      t.timestamps
    end
    add_index :submissions, [:problem_id, :user_id]
  end
end
