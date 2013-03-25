require 'spec_helper'

describe Submission do
  before { @p = FactoryGirl.build(:submission) }

  subject { @p }

  it { should respond_to(:content) }

  it { should be_valid }

  # User
  describe "when content is not present" do
    before { @p.content = " " }
    it { should_not be_valid }
  end
  describe "when content is too long" do
    before { @p.content = "a" * 8001 }
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
