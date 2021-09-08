class AddForumseenToPoints < ActiveRecord::Migration[5.0]
  def change
    add_column :points, :forumseen, :datetime, :default => '2009-01-01 00:00:00'
  end
end
