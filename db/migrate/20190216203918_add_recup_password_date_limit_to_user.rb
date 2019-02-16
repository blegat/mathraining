class AddRecupPasswordDateLimitToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :recup_password_date_limit, :datetime
  end
end
