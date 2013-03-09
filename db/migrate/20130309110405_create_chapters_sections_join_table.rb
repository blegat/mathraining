class CreateChaptersSectionsJoinTable < ActiveRecord::Migration
  def change
  create_table :chapters_sections, :id => false do |t|
    t.integer :chapter_id
  	t.integer :section_id
  	end
  end
end
