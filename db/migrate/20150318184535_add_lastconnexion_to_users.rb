class AddLastconnexionToUsers < ActiveRecord::Migration
  def change
    add_column :users, :last_connexion, :date
  end
end
