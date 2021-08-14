#encoding: utf-8

# == Schema Information
#
# Table name: visitors
#
#  id           :integer          not null, primary key
#  date         :date
#  number_user  :integer
#  number_admin :integer
#
class Visitor < ActiveRecord::Base
  def self.compute
    # Get date of yesterday
    timenow = DateTime.now.in_time_zone
    if(timenow.hour == 0) # In case of ~00:00
      yesterday = timenow.to_date - 1.day
    elsif(timenow.hour == 23) # In case of ~23:59
      yesterday = timenow.to_date
    else # Strange: do not compute visitors
      return
    end
    
    # Check if already computed (strange)
    if Visitor.where(:date => yesterday).count > 0
      return
    end
    
    # Compute number of users and admins connected yesterday
    num_users = User.where("admin = ? AND last_connexion >= ?", false, yesterday).count
    num_admins = User.where("admin = ? AND last_connexion >= ?", true, yesterday).count
    
    # Create new Visitor element
    v = Visitor.new
    v.date = yesterday
    v.number_user = num_users
    v.number_admin = num_admins
    v.save    
  end
end
