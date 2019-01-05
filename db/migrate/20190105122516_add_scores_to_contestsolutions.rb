class AddScoresToContestsolutions < ActiveRecord::Migration[5.0]
  def change
    add_column :contestsolutions, :score, :integer, default: -1
    remove_column :contestsolutions, :correct, :boolean
    add_column :contestorganizations, :id, :primary_key
  end
end
