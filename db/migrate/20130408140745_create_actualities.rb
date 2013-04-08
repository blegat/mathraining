class CreateActualities < ActiveRecord::Migration
  def change
    create_table :actualities do |t|
      t.string :title
      t.text :content
      t.boolean :tostudents
      t.timestamps
    end
  end
end
