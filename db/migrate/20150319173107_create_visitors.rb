class CreateVisitors < ActiveRecord::Migration
  def change
    create_table :visitors do |t|
      t.date :date
      t.integer :number_user
      t.integer :number_admin
    end

    add_index :visitors, :date
  end
end
