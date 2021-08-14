class DeleteFontColor < ActiveRecord::Migration[5.0]
  def change
    remove_column :colors, :font_color
  end
end
