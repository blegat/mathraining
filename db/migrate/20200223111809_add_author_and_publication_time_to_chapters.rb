class AddAuthorAndPublicationTimeToChapters < ActiveRecord::Migration[5.0]
  def change
    add_column :chapters, :author, :string
    add_column :chapters, :publication_time, :date
  end
end
