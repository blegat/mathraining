# == Schema Information
#
# Table name: contestproblems
#
#  id              :integer          not null, primary key
#  contest_id      :integer
#  number          :integer
#  statement       :text
#  origin          :string
#  start_time      :datetime
#  end_time        :datetime
#  status          :integer          default("in_construction")
#  reminder_status :integer          default("no_reminder_sent")
#
require "spec_helper"

describe Contestproblem, contestproblem: true do
  let!(:contestproblem) { FactoryGirl.build(:contestproblem) }

  subject { contestproblem }

  it { should be_valid }

  # Statement
  describe "when statement is not present" do
    before { contestproblem.statement = nil }
    it { should_not be_valid }
  end
  
  describe "when statement is too long" do
    before { contestproblem.statement = "a" * 16001 }
    it { should_not be_valid }
  end
  
  # Origin
  describe "when origin is too long" do
    before { contestproblem.origin = "a" * 257 }
    it { should_not be_valid }
  end
  
  # Start time
  describe "when start_time is not present" do
    before { contestproblem.start_time = nil }
    it { should_not be_valid }
  end
  
  # End time
  describe "when end_time is not present" do
    before { contestproblem.end_time = nil }
    it { should_not be_valid }
  end
  
  # Number
  describe "when number is not present" do
    before { contestproblem.number = nil }
    it { should_not be_valid }
  end
  
  describe "when number is negative" do
    before { contestproblem.number = -1 }
    it { should_not be_valid }
  end
end
