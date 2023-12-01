# == Schema Information
#
# Table name: contestorganizations
#
#  id         :integer          not null, primary key
#  contest_id :integer
#  user_id    :integer
#
require "spec_helper"

describe Contestorganization, contest: true do
  let!(:user) { FactoryGirl.create(:user) }
  let!(:contest) { FactoryGirl.create(:contest) }
  let!(:contestorganization) { Contestorganization.new(contest: contest, user: user) }

  subject { contestorganization }

  it { should be_valid }

  # Uniqueness
  describe "when already present" do
    before { Contestorganization.create(contest: contest, user: user) }
    it { should_not be_valid }
  end
end
