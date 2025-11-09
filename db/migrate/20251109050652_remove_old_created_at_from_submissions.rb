class RemoveOldCreatedAtFromSubmissions < ActiveRecord::Migration[7.1]
  def change
    remove_column :submissions, :old_created_at
  end
end
