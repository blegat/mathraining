class CreateSolvedqcms < ActiveRecord::Migration
  def change
    create_table :solvedqcms do |t|
      t.integer :user_id
      t.integer :qcm_id
      t.boolean :correct
      t.integer :nb_guess

      t.timestamps
    end
    
    add_index :solvedqcms, :user_id
  end
end
