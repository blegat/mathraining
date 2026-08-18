# == Schema Information
#
# Table name: solvedproblems
#
#  id              :integer          not null, primary key
#  correction_time :datetime
#  resolution_time :datetime
#  problem_id      :integer
#  submission_id   :integer
#  user_id         :integer
#
# Indexes
#
#  index_solvedproblems_on_problem_id                   (problem_id)
#  index_solvedproblems_on_resolution_time              (resolution_time)
#  index_solvedproblems_on_submission_id                (submission_id)
#  index_solvedproblems_on_user_id                      (user_id)
#  index_solvedproblems_on_user_id_and_problem_id       (user_id,problem_id) UNIQUE
#  index_solvedproblems_on_user_id_and_resolution_time  (user_id,resolution_time)
#
require "spec_helper"

describe Solvedproblem, solvedproblem: true do

  let(:sp) { FactoryBot.build(:solvedproblem) }

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
