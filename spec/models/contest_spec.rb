# == Schema Information
#
# Table name: contests
#
#  id               :integer          not null, primary key
#  number           :integer
#  description      :text
#  status           :integer          default("in_construction")
#  medal            :boolean          default(FALSE)
#  start_time       :datetime
#  end_time         :datetime
#  num_problems     :integer          default(0)
#  num_participants :integer          default(0)
#  bronze_cutoff    :integer          default(0)
#  silver_cutoff    :integer          default(0)
#  gold_cutoff      :integer          default(0)
#
require "spec_helper"

describe Contest, contest: true do
  let!(:contest) { FactoryGirl.build(:contest) }

  subject { contest }

  it { should be_valid }

  # Description
  describe "when description is not present" do
    before { contest.description = nil }
    it { should_not be_valid }
  end
  
  describe "when description is too long" do
    before { contest.description = "a" * 16001 }
    it { should_not be_valid }
  end
  
  # Status
  describe "when status is not present" do
    before { contest.status = nil }
    it { should_not be_valid }
  end
  
  # Number
  describe "when number is zero" do
    before { contest.number = 0 }
    it { should_not be_valid }
  end
  
  # Bronze cutoff
  describe "when bronze_cutoff is negative" do
    before { contest.bronze_cutoff = -1 }
    it { should_not be_valid }
  end
  
  # Silver cutoff
  describe "when silver_cutoff is negative" do
    before { contest.silver_cutoff = -1 }
    it { should_not be_valid }
  end
  
  # Gold cutoff
  describe "when gold_cutoff is negative" do
    before { contest.gold_cutoff = -1 }
    it { should_not be_valid }
  end
  
  # Update problem numbers and contest details
  describe "when there are some problems" do
    let!(:d) { Date.new(2030, 1, 1).to_datetime }
    let!(:contestproblem1) { FactoryGirl.create(:contestproblem, contest: contest, number: 20, start_time: d + 2.days, end_time: d + 3.days) }
    let!(:contestproblem2) { FactoryGirl.create(:contestproblem, contest: contest, number: 15, start_time: d + 3.days, end_time: d + 5.days) }
    let!(:contestproblem3) { FactoryGirl.create(:contestproblem, contest: contest, number: 4, start_time: d + 3.days, end_time: d + 4.days) }
    
    describe "computation of new numbers should be correct" do
      before do
        contest.update_problem_numbers
        contestproblem1.reload
        contestproblem2.reload
        contestproblem3.reload
      end
      specify do
        expect(contestproblem1.number).to eq(1)
        expect(contestproblem2.number).to eq(3)
        expect(contestproblem3.number).to eq(2)
      end
    end
    
    describe "computation of contest details should be correct" do
      before do
        contest.update_details
        contest.reload
      end
      specify do
        expect(contest.num_problems).to eq(3)
        expect(contest.start_time).to eq(contestproblem1.start_time)
        expect(contest.end_time).to eq(contestproblem2.end_time)
      end
    end
  end
end
