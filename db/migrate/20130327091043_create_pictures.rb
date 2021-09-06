class CreatePictures < ActiveRecord::Migration[5.0]
  def change
    create_table :pictures do |t|
      t.integer :user_id
    end
    add_index :pictures, :user_id
  end
end
