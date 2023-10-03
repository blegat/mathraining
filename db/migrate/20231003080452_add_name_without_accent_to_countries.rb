class AddNameWithoutAccentToCountries < ActiveRecord::Migration[7.0]
  def change
    add_column :countries, :name_without_accent, :string
    add_index :countries, :name_without_accent
    up_only do
      Country.all.each do |c|
        c.name_without_accent = I18n.transliterate(c.name)
        c.save
      end
    end
  end
end
