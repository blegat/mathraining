class CreateExternalsolutionsAndExtracts < ActiveRecord::Migration[7.0]
  def change
    create_table :externalsolutions do |t|
      t.references :problem
      t.text :url
    end
    
    create_table :extracts do |t|
      t.references :externalsolution
      t.string :text
    end
  end
end
