class DeleteAdminUser < ActiveRecord::Migration
  def change
    remove_column :subjects, :admin_user
    remove_column :messages, :admin_user
  end
end
