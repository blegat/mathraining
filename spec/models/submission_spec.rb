# == Schema Information
#
# Table name: submissions
#
#  id                :integer          not null, primary key
#  problem_id        :integer
#  user_id           :integer
#  content           :text
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  status            :integer          default(0)
#  intest            :boolean          default(FALSE)
#  visible           :boolean          default(TRUE)
#  score             :integer          default(-1)
#  last_comment_time :datetime
#  star              :boolean          default(FALSE)
#
require "spec_helper"

describe Submission do
  before { @p = FactoryGirl.build(:submission) }

  subject { @p }

  it { should respond_to(:content) }
  it { should respond_to(:status) }

  it { should be_valid }

  # Content
  describe "when content is not present" do
    before { @p.content = " " }
    it { should_not be_valid }
  end
  describe "when content is too long" do
    before { @p.content = "a" * 16001 }
    it { should_not be_valid }
  end

  # User
  describe "when user is not present" do
    before { @p.user = nil }
    it { should_not be_valid }
  end

  # Problem
  describe "when problem is not present" do
    before { @p.problem = nil }
    it { should_not be_valid }
  end

end
