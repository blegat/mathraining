# == Schema Information
#
# Table name: visitors
#
#  id        :integer          not null, primary key
#  date      :date
#  nb_users  :integer
#  nb_admins :integer
#
require "spec_helper"

describe Visitor, visitor: true do
  let(:visitor) { Visitor.new(date: Date.today - 1.day, nb_users: 342, nb_admins: 2) }

  subject { visitor }

  it { should be_valid }

  # Date
  describe "when date is not present" do
    before { visitor.date = nil }
    it { should_not be_valid }
  end
  describe "when date is not unique" do
    before { Visitor.create(date: visitor.date, nb_users: 145, nb_admins: 4) }
    it { should_not be_valid }
  end

  # Number of users
  describe "when nb_users is not present" do
    before { visitor.nb_users = nil }
    it { should_not be_valid }
  end
  describe "when nb_users is negative" do
    before { visitor.nb_users = -1 }
    it { should_not be_valid }
  end

  # Number of admins
  describe "when nb_admins is not present" do
    before { visitor.nb_admins = nil }
    it { should_not be_valid }
  end
  describe "when nb_admins is negative" do
    before { visitor.nb_admins = -1 }
    it { should_not be_valid }
  end
  
  # compute (used by cron job at midnight)
  describe "compute" do
    let(:user1) { FactoryBot.create(:user) }
    let(:user2) { FactoryBot.create(:user) }
    let(:admin) { FactoryBot.create(:admin) }
  
    describe "should work just after midnight" do
      let!(:time_now) { Time.zone.local(2021, 12, 3, 0, 0, 23) } # We set current date to 03/12/2021 at 00:00:23
      let!(:date_now) { time_now.to_date }
      before do
        travel_to time_now
        user1.update_attribute(:last_connexion_date, date_now - 1)
        user2.update_attribute(:last_connexion_date, date_now - 2)
        admin.update_attribute(:last_connexion_date, date_now) # Should also be counted for yesterday
        Visitor.compute
        travel_back
      end
      let!(:visitor_data) { Visitor.where(:date => date_now - 1).first }
      specify do
        expect(visitor_data.nb_users).to eq(1)
        expect(visitor_data.nb_admins).to eq(1)
      end
    end
    
    describe "should work just after midnight when called twice" do # In case crontab does two times the job for some reason
      let!(:time_now) { Time.zone.local(2021, 12, 3, 0, 0, 23) } # We set current date to 03/12/2021 at 00:00:23
      let!(:date_now) { time_now.to_date }
      let!(:num_visitor_records_before) { Visitor.count }
      before do
        travel_to time_now
        user1.update_attribute(:last_connexion_date, date_now)
        user2.update_attribute(:last_connexion_date, date_now)
        admin.update_attribute(:last_connexion_date, date_now - 1) # Should also be counted for yesterday
        Visitor.compute
        Visitor.compute # The second time it should do nothing
        travel_back
      end
      let!(:visitor_data) { Visitor.where(:date => date_now - 1).first }
      specify do
        expect(Visitor.count).to eq(num_visitor_records_before + 1)
        expect(visitor_data.nb_users).to eq(2)
        expect(visitor_data.nb_admins).to eq(1)
      end
    end
    
    describe "should work just before midnight" do # Should not occur in general, but in case crontab is too early...
      let!(:time_now) { Time.zone.local(2021, 12, 3, 23, 58, 12) } # We set current date to 03/12/2021 at 23:58:12 
      let!(:date_now) { time_now.to_date }
      before do
        travel_to time_now
        user1.update_attribute(:last_connexion_date, date_now)
        user2.update_attribute(:last_connexion_date, date_now - 1) # Should NOT count this time
        admin.update_attribute(:last_connexion_date, date_now - 2)
        Visitor.compute
        travel_back
      end
      let!(:visitor_data) { Visitor.where(:date => date_now).first }
      specify do
        expect(visitor_data.nb_users).to eq(1)
        expect(visitor_data.nb_admins).to eq(0)
      end
    end
    
    describe "should not do anything in the middle of the day" do # Should not occur in general, but in case crontab is completely broken
      let!(:time_now) { Time.zone.local(2021, 12, 3, 7, 23, 15) } # We set current date to 03/12/2021 at 07:23:15 
      let!(:date_now) { time_now.to_date }
      let!(:num_visitor_records_before) { Visitor.count }
      before do
        travel_to time_now
        user1.update_attribute(:last_connexion_date, date_now)
        user2.update_attribute(:last_connexion_date, date_now - 1)
        admin.update_attribute(:last_connexion_date, date_now - 2)
        Visitor.compute
        travel_back
      end
      specify { expect(Visitor.count).to eq(num_visitor_records_before) }
    end
  end
end
