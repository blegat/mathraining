class ManySectionsToOneSectionBis < ActiveRecord::Migration
  def change
    add_column :chapters, :section_id, :integer, :default => 7
  end
end
