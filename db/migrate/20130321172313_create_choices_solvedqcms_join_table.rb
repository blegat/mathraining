class CreateChoicesSolvedqcmsJoinTable < ActiveRecord::Migration[5.0]
  def change
    create_table :choices_solvedqcms, :id => false do |t|
      t.references :choice
      t.references :solvedqcm
    end
    
    add_index :choices_solvedqcms, :solvedqcm_id
  end
  
end
