class AddOrderToChapters < ActiveRecord::Migration[5.0]
  def change
    add_column :chapters, :position, :integer, default: 0
  end
end
