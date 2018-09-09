class AddPositionToItems < ActiveRecord::Migration[5.0]
  def change
    add_column :items, :position, :integer
    
    #pos = Array.new
    #Question.all.each do |q|
    #  pos[q.id] = 0
    #end
    #
    #Item.order(:id).all.each do |i|
    #  pos[i.question_id] = pos[i.question_id] + 1
    #  i.position = pos[i.question_id]
    #  i.save
    #end
  end
end
