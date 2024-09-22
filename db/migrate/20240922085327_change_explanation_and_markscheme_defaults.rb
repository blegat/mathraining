class ChangeExplanationAndMarkschemeDefaults < ActiveRecord::Migration[7.0]
  def change
    change_column_default :problems, :explanation, from: "", to: "-" 
    change_column_default :problems, :markscheme, from: "", to: "-" 
    
    up_only do
      Problem.all.each do |p|
        p.explanation = "-" if p.explanation == ""
        p.markscheme = "-" if p.markscheme == ""
        p.save
      end
    end
  end
end
