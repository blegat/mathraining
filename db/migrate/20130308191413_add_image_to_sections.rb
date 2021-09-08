class AddImageToSections < ActiveRecord::Migration[5.0]
  def change
    add_column :sections, :image, :string
  end
end
