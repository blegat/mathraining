class CreateFollowings < ActiveRecord::Migration[5.0]
  def change
    create_table :followings do |t|
      t.references :submission
      t.references :user

      t.boolean :read

      t.timestamps
    end
    add_index :followings, [:submission_id, :user_id]
  end
end
