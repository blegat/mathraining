class RemoveVisibleFromSubmissions < ActiveRecord::Migration[7.1]
  def change
    remove_column :submissions, :visible, :boolean
  end
end
