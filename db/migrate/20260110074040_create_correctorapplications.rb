class CreateCorrectorapplications < ActiveRecord::Migration[7.1]
  def change
    create_table :correctorapplications do |t|
      t.references :user
      t.text :content
      t.boolean :processed, default: false
      t.references :tchatmessage
      t.datetime :created_at, precision: nil, null: false
    end
  end
end
