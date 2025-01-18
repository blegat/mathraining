class CreateSavedreplies < ActiveRecord::Migration[7.1]
  def change
    create_table :savedreplies do |t|
      t.references :problem
      t.text :content
      t.integer :nb_uses, :default => 0
    end
  end
end
