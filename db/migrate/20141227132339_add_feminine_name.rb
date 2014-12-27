class AddFeminineName < ActiveRecord::Migration
  def change
    add_column :colors, :femininename, :string
    add_column :users, :sex, :integer, default: 0
  end
end
