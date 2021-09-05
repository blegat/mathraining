# == Schema Information
#
# Table name: solvedproblems
#
#  id             :integer          not null, primary key
#  problem_id     :integer
#  user_id        :integer
#  created_at     :datetime
#  updated_at     :datetime
#  resolutiontime :datetime
#  submission_id  :integer
#  truetime       :datetime
#
require "spec_helper"

describe Solvedproblem do

  before { @sp = FactoryGirl.build(:solvedproblem) }

  subject { @sp }

  it { should respond_to(:problem) }
  it { should respond_to(:user) }

  it { should be_valid }

  # Problem
  describe "when problem is not present" do
    before { @sp.problem = nil }
    it { should_not be_valid }
  end

  # User
  describe "when user is not present" do
    before { @sp.user = nil }
    it { should_not be_valid }
  end

end
