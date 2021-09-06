class RemovePlural < ActiveRecord::Migration[5.0]
  def change
    remove_column :colors, :plural_name
  end
end
