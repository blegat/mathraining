class CreatePrivacyPolicy < ActiveRecord::Migration[5.0]
  def change
    create_table :privacypolicies do |t|
      t.text :content
      t.text :description
      t.datetime :publication
      t.boolean :online, default: false
    end
    remove_column :users, :old_country
    rename_column :users, :consent, :consent_date
    add_column :users, :last_policy_read, :boolean, default: false
  end
end
