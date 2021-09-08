class ManySectionsToOneSectionBis < ActiveRecord::Migration[5.0]
  def change
    add_reference :chapters, :section
  end
end
