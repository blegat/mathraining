class CreateChaptercreations < ActiveRecord::Migration[5.0]
  def change
    create_table :chaptercreations do |t|
      t.references :user
      t.references :chapter
    end
  end
end
