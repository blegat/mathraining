class CreateWepionForum < ActiveRecord::Migration[5.0]
  def change
    add_column :subjects, :wepion, :boolean, :default => false
    add_column :users, :wepion, :boolean, :default => false
  end
end
