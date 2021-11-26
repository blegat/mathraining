class AddIndexOnSubmissions < ActiveRecord::Migration[5.2]
  def change
    add_index :submissions, :status
    add_index :submissions, :created_at
  end
end
