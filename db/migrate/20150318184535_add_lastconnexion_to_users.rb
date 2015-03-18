class AddLastconnexionToUsers < ActiveRecord::Migration
  def change
    add_column :users, :last_connexion, :date, :default => '2009-01-01'
  end
end
