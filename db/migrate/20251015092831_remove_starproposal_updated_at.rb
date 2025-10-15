class RemoveStarproposalUpdatedAt < ActiveRecord::Migration[7.1]
  def change
    remove_column :starproposals, :updated_at
  end
end
