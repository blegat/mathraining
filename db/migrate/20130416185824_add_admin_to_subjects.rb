class AddAdminToSubjects < ActiveRecord::Migration
  def change
    add_column :subjects, :admin, :boolean, :default => false
    add_column :subjects, :admin_user, :boolean, :default => false
    add_column :messages, :admin_user, :boolean, :default => false
  end
end
