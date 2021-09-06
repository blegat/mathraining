class PutRatingInUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :rating, :integer, default: 0
    add_column :users, :forumseen, :datetime, :default => '2009-01-01 00:00:00'
  end
end
