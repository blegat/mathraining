class UnifyFilesAndFakefiles < ActiveRecord::Migration[5.0]
  def change
    create_table :myfiles do |t|
      t.references :myfiletable, polymorphic: true
      t.string :file_file_name
      t.string :file_content_type
      t.integer :file_file_size
      t.datetime :file_updated_at
    end
    
    create_table :fakefiles do |t|
    	t.references :fakefiletable, polymorphic: true
    	t.string :file_file_name
      t.string :file_content_type
      t.integer :file_file_size
      t.datetime :file_updated_at
    end
  end
end
