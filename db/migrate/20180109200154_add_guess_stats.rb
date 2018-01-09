class AddGuessStats < ActiveRecord::Migration[5.0]
  def change
    add_column :exercises, :nb_tries, :integer, :default => 0
    add_column :exercises, :nb_firstguess, :integer, :default => 0
    add_column :qcms, :nb_tries, :integer, :default => 0
    add_column :qcms, :nb_firstguess, :integer, :default => 0
  end
end
