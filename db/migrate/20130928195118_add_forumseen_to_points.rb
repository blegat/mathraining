class AddForumseenToPoints < ActiveRecord::Migration
  def change
    add_column :points, :forumseen, :datetime, :default => '2009-01-01 00:00:00'
  end
end
