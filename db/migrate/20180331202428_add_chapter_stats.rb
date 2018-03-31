class AddChapterStats < ActiveRecord::Migration[5.0]
  def change
    add_column :chapters, :nb_tries, :integer, :default => 0
    add_column :chapters, :nb_solved, :integer, :default => 0
  end
end
