class AddLastTimeToSubjects < ActiveRecord::Migration
  def change
    add_column :subjects, :lastcomment, :datetime
  end
end
