class PutRatingInUser < ActiveRecord::Migration
  def change
    add_column :users, :rating, :integer, default: 0
    add_column :users, :forumseen, :datetime, :default => '2009-01-01 00:00:00'
  end
end
