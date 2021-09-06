class AddLastTimeToSubjects < ActiveRecord::Migration[5.0]
  def change
    add_column :subjects, :lastcomment, :datetime
  end
end
