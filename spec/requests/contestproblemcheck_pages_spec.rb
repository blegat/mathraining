# -*- coding: utf-8 -*-
require "spec_helper"

describe "Contestproblemcheck pages" do

  subject { page }

  let!(:user_following_contest) { FactoryGirl.create(:user) }
  let!(:user_following_subject) { FactoryGirl.create(:user) }
  
  let!(:category) { FactoryGirl.create(:category, name: "Mathraining") } # For the Forum subject
    
  let!(:running_contest) { FactoryGirl.create(:contest, status: 1) }
  let!(:running_contestproblem) { FactoryGirl.create(:contestproblem, contest: running_contest, number: 1, status: 1, start_time: DateTime.now + 2.days, end_time: DateTime.now + 2.days) }
  let!(:running_contestproblemcheck) { FactoryGirl.create(:contestproblemcheck, contestproblem: running_contestproblem) }
  let!(:running_contestsubject) { FactoryGirl.create(:subject, contest: running_contest, category: category, lastcomment: DateTime.now - 2.days) }
  
  before do
    Followingsubject.create(:subject => running_contestsubject, :user => user_following_subject)
    Followingcontest.create(:contest => running_contest, :user => user_following_contest)
  end
  
  describe "anyone" do
    before { sign_in user_following_contest }
  
    describe "visits a contest just before problem publication" do
      before do
        running_contestproblem.start_time = DateTime.now + 5.minutes
        running_contestproblem.save
        visit contest_path(running_contest)
        running_contestproblem.reload
      end
      specify do
        expect(running_contestproblem.status).to eq(1)
        expect(page).to have_no_content(running_contestproblem.statement)
      end
    end
  
    describe "visits a contest just after problem publication" do
      before do
        running_contestproblem.start_time = DateTime.now - 1.minute
        running_contestproblem.save
        visit contest_path(running_contest)
        running_contestproblem.reload
      end
      specify do
        expect(running_contestproblem.status).to eq(2)
        expect(page).to have_content(running_contestproblem.statement)
      end
    end
    
    describe "visits a contest just after problem ends" do
      before do
        running_contestproblem.status = 2
        running_contestproblem.start_time = DateTime.now - 120.minutes
        running_contestproblem.end_time = DateTime.now - 1.minute
        running_contestproblem.save
        visit contest_path(running_contest)
        running_contestproblem.reload
      end
      specify do
        expect(running_contestproblem.status).to eq(3)
        expect(page).to have_content("En cours de correction")
      end
    end
  end
  
  describe "cron job" do
    describe "checks contestproblem one day before publication" do
      let!(:num_messages_before) { running_contestsubject.messages.count }
      before do
        running_contestproblem.start_time = DateTime.now + 1.day - 2.minutes
        running_contestproblem.end_time = running_contestproblem.start_time + 1.hour
        running_contestproblem.reminder_status = 0
        running_contestproblem.save
        Contest.check_contests_starts
        running_contestproblem.reload
        running_contestsubject.reload
      end
      specify do
        expect(running_contestproblem.reminder_status).to eq(1)
        expect(running_contestsubject.messages.count).to eq(num_messages_before + 1)
        expect(running_contestsubject.messages.order(:id).last.created_at).to eq(running_contestproblem.start_time - 1.day + running_contestproblem.number.seconds)
        expect(running_contestsubject.lastcomment).to eq(running_contestproblem.start_time - 1.day + running_contestproblem.number.seconds)
      end
    end
    
    describe "checks contestproblem just after publication" do
      let!(:num_messages_before) { running_contestsubject.messages.count }
      before do
        running_contestproblem.start_time = DateTime.now - 2.minutes
        running_contestproblem.end_time = running_contestproblem.start_time + 1.hour
        running_contestproblem.reminder_status = 1
        running_contestproblem.save
        Contest.check_contests_starts
        running_contestproblem.reload
        running_contestsubject.reload
      end
      specify do
        expect(running_contestproblem.reminder_status).to eq(2)
        expect(running_contestsubject.messages.count).to eq(num_messages_before + 1)
        expect(running_contestsubject.messages.order(:id).last.created_at).to eq(running_contestproblem.start_time + running_contestproblem.number.seconds)
        expect(running_contestsubject.lastcomment).to eq(running_contestproblem.start_time + running_contestproblem.number.seconds)
      end
    end
  end
end
