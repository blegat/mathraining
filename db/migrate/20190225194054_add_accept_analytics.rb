class AddAcceptAnalytics < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :accept_analytics, :boolean, default: true
  end
end
