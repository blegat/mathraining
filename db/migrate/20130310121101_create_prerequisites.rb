class CreatePrerequisites < ActiveRecord::Migration
  def change
    create_table :prerequisites do |t|
      t.references :prerequisite
      t.references :chapter
    end
  end
end
