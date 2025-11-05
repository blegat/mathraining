# == Schema Information
#
# Table name: contestproblemchecks
#
#  id                :integer          not null, primary key
#  contestproblem_id :integer
#
require "spec_helper"

describe Contestproblemcheck, contestproblem: true do
  let!(:contestproblem) { FactoryBot.create(:contestproblem) }
  let!(:contestproblemcheck) { Contestproblemcheck.new(contestproblem: contestproblem) }

  subject { contestproblemcheck }

  it { should be_valid }
  
  # Uniqueness
  describe "when already present" do
    before { Contestproblemcheck.create(contestproblem: contestproblem) }
    it { should_not be_valid }
  end
end
