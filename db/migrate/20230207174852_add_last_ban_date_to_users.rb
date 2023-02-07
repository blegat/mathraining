class AddLastBanDateToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :last_ban_date, :datetime
  end
end
