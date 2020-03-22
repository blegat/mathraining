# == Schema Information
#
# Table name: corrections
#
#  id            :integer          not null, primary key
#  user_id       :integer
#  submission_id :integer
#  content       :text
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

require "spec_helper"

describe Correction do
  before { @c = FactoryGirl.build(:correction) }

  subject { @c }

  it { should respond_to(:content) }
  it { should respond_to(:user) }
  it { should respond_to(:submission) }

  it { should be_valid }

  # Content
  describe "when content is not present" do
    before { @c.content = " " }
    it { should_not be_valid }
  end
  describe "when content is too long" do
    before { @c.content = "a" * 16001 }
    it { should_not be_valid }
  end

  # User
  describe "when user is not present" do
    before { @c.user = nil }
    it { should_not be_valid }
  end

  # Submission
  describe "when submission is not present" do
    before { @c.submission = nil }
    it { should_not be_valid }
  end


end
