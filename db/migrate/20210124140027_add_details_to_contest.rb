class AddDetailsToContest < ActiveRecord::Migration[5.0]
  def change
    add_column :contests, :start_time, :datetime
    add_column :contests, :end_time, :datetime
    add_column :contests, :num_problems, :integer, :default => 0
    add_column :contests, :num_participants, :integer, :default => 0 
  end
end
