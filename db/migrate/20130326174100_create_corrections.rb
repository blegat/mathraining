class CreateCorrections < ActiveRecord::Migration
  def change
    create_table :corrections do |t|
      t.references :user
      t.references :submission
      t.text :content

      t.timestamps
    end
    add_index :corrections, :submission_id
  end
end
