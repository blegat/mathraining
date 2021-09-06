class AddStarsToSubmissions < ActiveRecord::Migration[5.0]
  def change
    add_column :submissions, :star, :boolean, :default => false
  end
end
