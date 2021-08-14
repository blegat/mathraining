# == Schema Information
#
# Table name: actualities
#
#  id         :integer          not null, primary key
#  title      :string
#  content    :text
#  created_at :datetime
#  updated_at :datetime
#
require "spec_helper"

describe Actuality do
  before { @actuality = FactoryGirl.build(:actuality) }

  subject { @actuality }

  it { should respond_to(:title) }
  it { should respond_to(:content) }
  
  it { should be_valid }

  # Title
  describe "when title is not present" do
    before { @actuality.title = nil }
    it { should_not be_valid }
  end
  describe "when title is too long" do
    before { @actuality.title = "a" * 256 }
    it { should_not be_valid }
  end

  # Content
  describe "when content is not present" do
    before { @actuality.content = nil }
    it { should_not be_valid }
  end
  describe "when content is ok" do
    before { @actuality.content = "Coucou" }
    it { should be_valid }
  end

end
