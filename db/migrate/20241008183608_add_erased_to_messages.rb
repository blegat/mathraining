class AddErasedToMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :messages, :erased, :boolean, default: false
  end
end
