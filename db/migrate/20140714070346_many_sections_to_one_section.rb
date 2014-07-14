class ManySectionsToOneSection < ActiveRecord::Migration
  def change
    drop_table :chapters_sections
  end
end
