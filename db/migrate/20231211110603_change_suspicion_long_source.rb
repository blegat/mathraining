class ChangeSuspicionLongSource < ActiveRecord::Migration[7.0]
  def up
    change_column :suspicions, :source, :text
  end

  def down
    add_column :suspicions, :tmp_source, :string
    
    Suspicion.find_each do |s|
      tmp_source = (s.source.length > 255 ? s.source[0,254] : s.source)
      s.update_column(:tmp_source, tmp_source)
    end
    
    remove_column :suspicions, :source
    rename_column :suspicions, :tmp_source, :source
  end
end
