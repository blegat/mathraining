class CreateSuspicions < ActiveRecord::Migration[5.2]
  def change
    create_table :suspicions do |t|
      t.references :submission
      t.references :user
      t.string :source
      t.integer :status, :default => 0
      t.timestamps
    end
  end
end
