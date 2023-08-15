class CreateStarproposals < ActiveRecord::Migration[5.2]
  def change
    create_table :starproposals do |t|
      t.references :submission
      t.references :user
      t.string :reason
      t.string :answer
      t.integer :status, :default => 0
      t.timestamps
    end
  end
end
