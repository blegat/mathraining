class CreateVisitors < ActiveRecord::Migration
  def change
    create_table :visitors do |t|
      t.date :date
      t.integer :number
    end

    add_index :visitors, :date
  end
end
