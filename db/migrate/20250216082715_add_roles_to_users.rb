class AddRolesToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :role, :integer, :default => 1
    
    up_only do
      User.where(:root => true).update_all(:role => :root)
      User.where(:admin => true, :root => false).update_all(:role => :administrator)
      User.where(:active => false).update_all(:role => :deleted)
    end
    
    remove_column :users, :admin, :boolean, :default => false
    remove_column :users, :root, :boolean, :default => false
    remove_column :users, :active, :boolean, :default => true
    
    add_index :users, [:role, :rating], order: {rating: :desc}
    add_index :users, [:role, :country_id, :rating], order: {rating: :desc}
    add_index :users, [:role, :corrector]
    add_index :users, [:valid_name, :email_confirm]
  end
end
