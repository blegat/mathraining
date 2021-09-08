class AddCountryAndYear < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :year, :integer, :default => 0
    add_column :users, :country, :string
  end
end
