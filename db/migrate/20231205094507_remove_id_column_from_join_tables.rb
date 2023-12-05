class RemoveIdColumnFromJoinTables < ActiveRecord::Migration[7.0]
  def change
    remove_column :followingsubjects, :id
    remove_column :followingcontests, :id
    remove_column :followingusers, :id
    remove_column :chaptercreations, :id
    remove_column :contestorganizations, :id
    remove_column :notifs, :id
  end
end
