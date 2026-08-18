class ReplaceProblemOnlineWithStatus < ActiveRecord::Migration[8.1]
  def up
    add_column :problems, :status, :integer, :default => 0
    add_column :virtualtests, :status, :integer, :default => 0
    
    Problem.find_each do |p|
      p.update_column(:status, (p.online ? 1 : 0))
    end
    Virtualtest.find_each do |v|
      v.update_column(:status, (v.online ? 1 : 0))
    end
    
    remove_column :problems, :online
    remove_column :virtualtests, :online
  end

  def down
    add_column :problems, :online, :boolean, :default => false
    add_column :virtualtests, :online, :boolean, :default => false
    
    Problem.where(:status => 0).find_each do |p|
      p.update_column(:online, false)
    end
    Problem.where.not(:status => 0).find_each do |p|
      p.update_column(:online, true)
    end
    Virtualtest.where(:status => 0).find_each do |v|
      v.update_column(:online, false)
    end
    Virtualtest.where.not(:status => 0).find_each do |v|
      v.update_column(:online, true)
    end
    
    remove_column :problems, :status
    remove_column :virtualtests, :status
  end
end
