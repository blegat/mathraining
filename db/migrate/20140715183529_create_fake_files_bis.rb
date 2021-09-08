class CreateFakeFilesBis < ActiveRecord::Migration[5.0]
  def change
    create_table :fakesubmissionfiles do |t|
      t.references :submission
      t.string :file_file_name
      t.string :file_content_type
      t.integer :file_file_size
      t.datetime :file_updated_at
    end
    
    create_table :fakecorrectionfiles do |t|
      t.references :correction
      t.string :file_file_name
      t.string :file_content_type
      t.integer :file_file_size
      t.datetime :file_updated_at
    end
    
    create_table :fakesubjectfiles do |t|
      t.references :subject
      t.string :file_file_name
      t.string :file_content_type
      t.integer :file_file_size
      t.datetime :file_updated_at
    end
    
    create_table :fakemessagefiles do |t|
      t.references :message
      t.string :file_file_name
      t.string :file_content_type
      t.integer :file_file_size
      t.datetime :file_updated_at
    end
  end
end
