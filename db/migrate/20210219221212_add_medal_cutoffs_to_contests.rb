class AddMedalCutoffsToContests < ActiveRecord::Migration[5.0]
  def change
    add_column :contests, :bronze_cutoff, :integer, :default => 0
    add_column :contests, :silver_cutoff, :integer, :default => 0
    add_column :contests, :gold_cutoff, :integer, :default => 0
  end
end
