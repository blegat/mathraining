class CreateChoices < ActiveRecord::Migration[5.0]
  def change
    create_table :choices do |t|
      t.string :ans
      t.boolean :ok, default: false
      t.references :qcm

      t.timestamps
    end
  end
end
