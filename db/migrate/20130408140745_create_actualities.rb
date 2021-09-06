class CreateActualities < ActiveRecord::Migration[5.0]
  def change
    create_table :actualities do |t|
      t.string :title
      t.text :content
      t.boolean :tostudents
      t.timestamps
    end
  end
end
