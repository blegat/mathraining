class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :password_digest
      t.string :remember_token
      t.boolean :admin, default: false

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :remember_token
    # uniqueness of remember_token guaranteed SecureRandom.urlsafe_base64 ?
  end
end
