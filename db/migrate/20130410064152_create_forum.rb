class CreateForum < ActiveRecord::Migration[5.0]
  def change
    create_table :subjects do |t|
      t.string :title
      t.text :content
      t.references :user
      t.integer :chapter_id
      t.timestamps
    end
    add_index :subjects, :chapter_id
    
    create_table :messages do |t|
      t.text :content
      t.references :subject
      t.references :user
      t.timestamps
    end
    
    add_index :messages, :subject_id
  end
end
