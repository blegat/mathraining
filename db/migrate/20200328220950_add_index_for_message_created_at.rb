class AddIndexForMessageCreatedAt < ActiveRecord::Migration[5.0]
  def change
    remove_index :messages, :subject_id
    add_index :messages, [:subject_id, :created_at]

    remove_index :subjects, [:lastcomment, :admin]
    remove_index :subjects, :lastcomment
    add_index :subjects, [:important, :lastcomment], order: "DESC"
  end
end
