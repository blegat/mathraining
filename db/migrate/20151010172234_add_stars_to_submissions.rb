class AddStarsToSubmissions < ActiveRecord::Migration
  def change
    add_column :submissions, :star, :boolean, :default => false
  end
end
