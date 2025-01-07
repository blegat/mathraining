class CreateSanctions < ActiveRecord::Migration[7.1]
  def change
    create_table :sanctions do |t|
      t.references :user
      t.integer :sanction_type
      t.datetime :start_time
      t.integer :duration
      t.text :reason
    end
  end
end
