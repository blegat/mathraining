class RemovePlural < ActiveRecord::Migration
  def change
    remove_column :colors, :plural_name
  end
end
