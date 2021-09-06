class CreateTests < ActiveRecord::Migration[5.0]
  def change
    create_table :virtualtests do |t|
      t.integer :duration
      t.integer :number, default: 1
      t.boolean :online
    end
    
    create_table :takentests do |t|
      t.integer :user_id
      t.integer :virtualtest_id
      t.datetime :takentime
      t.integer :status
    end
    
    add_column :problems, :virtualtest_id, :integer, default: 0
    add_column :problems, :position, :integer, default: 0
    
    add_column :submissions, :intest, :boolean, default: false
    add_column :submissions, :visible, :boolean, default: true
    add_column :submissions, :score, :integer, default: -1
  end
end
