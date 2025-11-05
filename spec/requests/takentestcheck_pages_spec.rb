# -*- coding: utf-8 -*-
require "spec_helper"

describe "Takentestcheck pages", virtualtest: true do

  subject { page }
  
  let!(:user) { FactoryBot.create(:advanced_user) }
  let!(:virtualtest) { FactoryBot.create(:virtualtest, online: true) }
  let!(:problem1) { FactoryBot.create(:problem, virtualtest: virtualtest, online: true, position: 1) }
  let!(:problem2) { FactoryBot.create(:problem, virtualtest: virtualtest, online: true, position: 2) }
  let!(:takentest) { Takentest.create(user: user, virtualtest: virtualtest, taken_time: DateTime.now, status: :in_progress) }
  let!(:submission) { FactoryBot.create(:submission, user: user, problem: problem1, intest: true, status: :draft) }
  
  describe "anyone" do
    describe "visits any page just before the end of the test" do
      before do
        takentest.update_attribute(:taken_time, DateTime.now - (virtualtest.duration - 2).minutes)
        visit root_path
        takentest.reload
        submission.reload
      end
      specify do
        expect(takentest.in_progress?).to eq(true)
        expect(takentest.takentestcheck).not_to eq(nil)
        expect(submission.draft?).to eq(true)
      end
    end
  
    describe "visits any page just after the end of the test" do
      before do
        takentest.update_attribute(:taken_time, DateTime.now - (virtualtest.duration + 1).minutes)
        visit users_path
        takentest.reload
        submission.reload
      end
      specify do
        expect(takentest.finished?).to eq(true)
        expect(takentest.takentestcheck).to eq(nil)
        expect(submission.waiting?).to eq(true)
      end
    end
  end
end
