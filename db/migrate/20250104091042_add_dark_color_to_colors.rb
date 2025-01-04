class AddDarkColorToColors < ActiveRecord::Migration[7.1]
  def change
    add_column :colors, :dark_color, :string
    
    up_only do
      Color.all.each do |c|
        c.update_attribute(:dark_color, c.color)
      end
    end
  end
end
