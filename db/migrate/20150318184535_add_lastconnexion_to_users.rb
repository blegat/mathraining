class AddLastconnexionToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :last_connexion, :date, :default => '2009-01-01'
  end
end
