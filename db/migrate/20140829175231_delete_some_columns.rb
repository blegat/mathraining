class DeleteSomeColumns < ActiveRecord::Migration
  def change
    remove_column :problems, :chapter_id
    remove_column :problems, :position
    remove_column :problems, :name
  end
end
