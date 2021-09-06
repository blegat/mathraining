class AddLastcommentToSubmissions < ActiveRecord::Migration[5.0]
  def change
    add_column :submissions, :lastcomment, :datetime
  end
end
