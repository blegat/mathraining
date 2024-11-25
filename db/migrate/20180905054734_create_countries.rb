class CreateCountries < ActiveRecord::Migration[5.0]
  def change
    create_table :countries do |t|
      t.string :name
      t.string :code
    end
    
    rename_column :users, :country, :old_country
    add_reference :users, :country
  end
end
