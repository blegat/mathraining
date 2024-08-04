class AddCorrectorColorToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :corrector_color, :string
    
    up_only do
      User.where("admin = ? OR corrector = ?", true, true).each do |u|
        u.generate_corrector_color()
      end
    end
  end
end
