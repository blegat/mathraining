class CreateDiscussions < ActiveRecord::Migration[5.0]
  def change
    create_table :discussions do |t|
      t.datetime :last_message
      t.timestamps
    end

    create_table :links do |t|
      t.references :discussion
      t.references :user
      t.integer :nonread
    end

    create_table :tchatmessages do |t|
      t.text :content
      t.references :user
      t.references :discussion
      t.datetime :created_at
    end

    create_table :tchatmessagefiles do |t|
      t.references :tchatmessage
      t.string :file_file_name
      t.string :file_content_type
      t.integer :file_file_size
      t.datetime :file_updated_at
    end

    create_table :faketchatmessagefiles do |t|
      t.references :tchatmessage
      t.string :file_file_name
      t.string :file_content_type
      t.integer :file_file_size
      t.datetime :file_updated_at
    end

    add_index :tchatmessages, [:discussion_id, :created_at], order: "DESC", unique: true
  end
end
