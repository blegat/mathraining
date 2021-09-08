class CreateSolvedqcms < ActiveRecord::Migration[5.0]
  def change
    create_table :solvedqcms do |t|
      t.references :user
      t.references :qcm
      t.boolean :correct
      t.integer :nb_guess

      t.timestamps
    end
  end
end
