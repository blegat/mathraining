class CreateTheories < ActiveRecord::Migration[5.0]
  def change
    create_table :theories do |t|
      t.string :title
      t.text :content
      t.integer :chapter_id
      t.integer :order

      t.timestamps
    end
  end
end
