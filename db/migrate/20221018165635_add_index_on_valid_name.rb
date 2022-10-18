class AddIndexOnValidName < ActiveRecord::Migration[5.2]
  def change
    add_index :users, [:valid_name, :email_confirm, :admin]
  end
end
