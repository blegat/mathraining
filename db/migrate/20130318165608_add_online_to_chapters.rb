class AddOnlineToChapters < ActiveRecord::Migration
  def change
    add_column :chapters, :online, :boolean, default: false
  end
end
