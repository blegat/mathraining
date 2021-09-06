class AddOnlineToChapters < ActiveRecord::Migration[5.0]
  def change
    add_column :chapters, :online, :boolean, default: false
  end
end
