class CreateSponsorwords < ActiveRecord::Migration[7.0]
  def change
    create_table :sponsorwords do |t|
      t.string :word
      t.boolean :used, :default => false
    end
    add_index :sponsorwords, :word
  end
end
