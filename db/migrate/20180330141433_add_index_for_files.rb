class AddIndexForFiles < ActiveRecord::Migration[5.0]
  def change
    add_index :myfiles, :file_file_size, order: "DESC"
    add_index :fakefiles, :file_file_size, order: "DESC"
  end
end
