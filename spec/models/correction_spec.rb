require 'spec_helper'

describe Correction do
  before { @c = FactoryGirl.build(:correction) }

  subject { @c }

  it { should respond_to(:content) }

  it { should be_valid }

  # User
  describe "when content is not present" do
    before { @c.content = " " }
    it { should_not be_valid }
  end
  describe "when content is too long" do
    before { @c.content = "a" * 8001 }
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
