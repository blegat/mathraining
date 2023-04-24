class RemoveSomeUselessColumns < ActiveRecord::Migration[5.2]
  def change
    remove_column :solvedquestions, :updated_at # replaced by resolution_time which is more or less the same
    remove_column :suspicions, :updated_at
    remove_column :submissions, :updated_at
    remove_column :subjects, :updated_at
    remove_column :messages, :updated_at
    remove_column :users, :updated_at
  end
end
