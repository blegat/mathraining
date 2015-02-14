class AddCountryAndYear < ActiveRecord::Migration
  def change
    add_column :users, :year, :integer, :default => 0
    add_column :users, :country, :string
  end
end
