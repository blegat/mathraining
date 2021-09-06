class ManySectionsToOneSectionBis < ActiveRecord::Migration[5.0]
  def change
    add_column :chapters, :section, :references, :default => 7
  end
end
