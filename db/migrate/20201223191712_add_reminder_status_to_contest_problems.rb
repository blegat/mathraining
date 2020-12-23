class AddReminderStatusToContestProblems < ActiveRecord::Migration[5.0]
  def change
    add_column :contestproblems, :reminder_status, :integer, :default => 0
  end
end
