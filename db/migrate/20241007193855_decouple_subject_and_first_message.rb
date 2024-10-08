class DecoupleSubjectAndFirstMessage < ActiveRecord::Migration[7.0]
  def up
    execute("INSERT INTO messages (content, subject_id, user_id, created_at) SELECT content, id, user_id, created_at FROM subjects;")
    
    Myfile.where(:myfiletable_type => "Subject").each do |f|
      s = Subject.find_by_id(f.myfiletable_id)
      if s.nil?
        f.destroy
      else
        f.update_attribute(:myfiletable, s.messages.order(:created_at).first)
      end
    end
    
    Fakefile.where(:fakefiletable_type => "Subject").each do |f|
      s = Subject.find_by_id(f.fakefiletable_id)
      if s.nil?
        f.destroy
      else
        f.update_attribute(:fakefiletable, s.messages.order(:created_at).first)
      end
    end
  
    remove_column :subjects, :content, :text
    remove_column :subjects, :user_id, :integer
    remove_column :subjects, :created_at, :datetime
  end
  
  def down
    add_column :subjects, :content, :text
    add_column :subjects, :user_id, :integer
    add_column :subjects, :created_at, :datetime, precision: nil
    
    Myfile.where(:myfiletable_type => "Message").each do |f|
      m = Message.find_by_id(f.myfiletable_id)
      unless m.nil?
        s = m.subject
        if s.messages.order(:created_at).first == m
          f.update(:myfiletable_type => "Subject", :myfiletable_id => s.id)
        end
      end
    end
    
    Fakefile.where(:fakefiletable_type => "Message").each do |f|
      m = Message.find(f.fakefiletable_id)
      unless m.nil?
        s = m.subject
        if s.messages.order(:created_at).first == m
          f.update(:fakefiletable_type => "Subject", :fakefiletable_id => s.id)
        end
      end
    end
    
    Subject.all.each do |s|
      m = s.messages.order(:created_at).first
      unless m.nil?
        s.update(:content => m.content, :user_id => m.user_id, :created_at => m.created_at)
        m.destroy
      end
    end
  end
end
