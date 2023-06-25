class CreateGlobalVariable < ActiveRecord::Migration[5.2]
  def change
    create_table :globalvariables do |t|
      t.string :key
      t.boolean :value
      t.text :message
    end
  end
end
