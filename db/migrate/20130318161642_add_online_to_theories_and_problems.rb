class AddOnlineToTheoriesAndProblems < ActiveRecord::Migration[5.0]
  def change
    add_column :theories, :online, :boolean, default: false
    add_column :problems, :online, :boolean, default: false
  end
end
