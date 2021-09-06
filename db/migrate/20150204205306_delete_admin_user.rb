class DeleteAdminUser < ActiveRecord::Migration[5.0]
  def change
    remove_column :subjects, :admin_user
    remove_column :messages, :admin_user
  end
end
