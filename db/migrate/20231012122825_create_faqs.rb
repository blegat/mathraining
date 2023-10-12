class CreateFaqs < ActiveRecord::Migration[7.0]
  def change
    create_table :faqs do |t|
      t.text :question
      t.text :answer
      t.integer :position
    end
  end
end
