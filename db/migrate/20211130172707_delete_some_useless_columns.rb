class DeleteSomeUselessColumns < ActiveRecord::Migration[5.2]
  def change
    remove_column :actualities, :updated_at
    remove_column :chapters, :updated_at
    remove_column :chapters, :created_at
    remove_column :corrections, :updated_at
    remove_column :discussions, :created_at
    remove_column :discussions, :updated_at
    remove_column :followings, :updated_at
    remove_column :items, :created_at
    remove_column :items, :updated_at
    remove_column :notifs, :updated_at
    remove_column :problems, :created_at
    remove_column :problems, :updated_at
    remove_column :questions, :created_at
    remove_column :questions, :updated_at
    remove_column :sections, :created_at
    remove_column :sections, :updated_at
    remove_column :solvedproblems, :created_at
    remove_column :solvedproblems, :updated_at
    remove_column :solvedquestions, :created_at # NB: updated_at is important for the timer of 3 minutes after 3 wrong guesses
    remove_column :theories, :created_at
    remove_column :theories, :updated_at
  end
end
