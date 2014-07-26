class CreateColors < ActiveRecord::Migration
  def change
    create_table :colors do |t|
      t.integer :pt
      t.string :name
      t.string :plural_name
      t.string :color
      t.string :font_color
    end
  end
end
