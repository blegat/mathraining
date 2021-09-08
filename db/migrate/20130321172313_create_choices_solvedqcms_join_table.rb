class CreateChoicesSolvedqcmsJoinTable < ActiveRecord::Migration[5.0]
  def change
    create_table :choices_solvedqcms, :id => false do |t|
      t.references :choice
      t.references :solvedqcm
    end
  end
end
