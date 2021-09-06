class ManySectionsToOneSection < ActiveRecord::Migration[5.0]
  def change
    drop_table :chapters_sections
  end
end
