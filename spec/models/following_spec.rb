# == Schema Information
#
# Table name: followings
#
#  id            :integer          not null, primary key
#  submission_id :integer
#  user_id       :integer
#  read          :boolean
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

require 'spec_helper'

describe Following do

  before { @f = FactoryGirl.build(:following) }

  subject { @f }

  it { should respond_to(:submission) }
  it { should respond_to(:user) }
  it { should respond_to(:read) }

  it { should be_valid }

  # Submission
  describe "when submission is not present" do
    before { @f.submission = nil }
    it { should_not be_valid }
  end

  # User
  describe "when user is not present" do
    before { @f.user = nil }
    it { should_not be_valid }
  end

  # User & submission
  describe "when user and submission are already taken" do
    before { FactoryGirl.create(:following, user: @f.user, submission: @f.submission) }
    it { should_not be_valid }
  end

end
