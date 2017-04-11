class AddIndexesForSubject < ActiveRecord::Migration
  def change
    # For admins (only time)
    add_index :subjects, :lastcomment, order: :asc
    # For not admins (time and not admin). "Wepion"-only subjects are not a problem because there souldn't be much subjects most of the time
    add_index :subjects, [:lastcomment, :admin], order: {lastcomment: :asc}
  end
end
