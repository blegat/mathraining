class AddImageToSections < ActiveRecord::Migration
  def change
    add_column :sections, :image, :string
  end
end
