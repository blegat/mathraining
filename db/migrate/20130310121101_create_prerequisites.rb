class CreatePrerequisites < ActiveRecord::Migration[5.0]
  def change
    create_table :prerequisites do |t|
      t.references :prerequisite
      t.references :chapter
    end
  end
end
