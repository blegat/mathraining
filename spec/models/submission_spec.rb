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
    before { @p.content = "a" * 8001 }
    it { should_not be_valid }
  end

  # Status
  describe "when the status is not present" do
    before { @p.status = " " }
    it { should_not be_valid }
  end
  describe "when the status is not in the allowed range" do
    before { @p.status = 4 }
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
