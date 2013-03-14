class CreateChoices < ActiveRecord::Migration
  def change
    create_table :choices do |t|
      t.string :ans
      t.boolean :ok, default: false
      t.integer :qcm_id

      t.timestamps
    end
    
    add_index :choices, :qcm_id
  end
end
