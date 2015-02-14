class AddLastcommentToSubmissions < ActiveRecord::Migration
  def change
    add_column :submissions, :lastcomment, :datetime
  end
end
