class AddShortNamesForSections < ActiveRecord::Migration[5.2]
  def change
    add_column :sections, :abbreviation, :string
    add_column :sections, :short_abbreviation, :string
    add_column :sections, :initials, :string
  end
end
