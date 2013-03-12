class CreateTheories < ActiveRecord::Migration
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
