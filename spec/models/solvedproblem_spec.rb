# == Schema Information
#
# Table name: solvedproblems
#
#  id              :integer          not null, primary key
#  problem_id      :integer
#  user_id         :integer
#  correction_time :datetime
#  submission_id   :integer
#  resolution_time :datetime
#
require "spec_helper"

describe Solvedproblem, solvedproblem: true do

  let(:sp) { FactoryGirl.build(:solvedproblem) }

  subject { sp }
  
  it { should be_valid }
  
  # Correction time
  describe "when correction_time is not present" do
    before { sp.correction_time = nil }
    it { should_not be_valid }
  end
  
  # Resolution time
  describe "when resolution_time is not present" do
    before { sp.resolution_time = nil }
    it { should_not be_valid }
  end
end
