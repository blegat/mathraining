class CreateRecords < ActiveRecord::Migration[5.0]
  def change
    create_table :records do |t|
      t.date :date
      t.integer :number_submission
      t.integer :number_solved
      t.float :correction_time
      t.boolean :complete
    end
    
    add_index :records, :date
  end
end
