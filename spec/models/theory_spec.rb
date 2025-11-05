# == Schema Information
#
# Table name: theories
#
#  id         :integer          not null, primary key
#  title      :string
#  content    :text
#  chapter_id :integer
#  position   :integer
#  online     :boolean          default(FALSE)
#
require "spec_helper"

describe Theory, theory: true do

  let!(:theory) { FactoryBot.build(:theory) }

  subject { theory }

  it { should be_valid }

  # Title
  describe "when title is not present" do
    before { theory.title = " " }
    it { should_not be_valid }
  end
  describe "when title is too long" do
    before { theory.title = "a" * 256 }
    it { should_not be_valid }
  end
  
  # Content
  describe "when content is not present" do
    before { theory.content = " " }
    it { should_not be_valid }
  end
  describe "when content is too long" do
    before { theory.content = "a" * 16001 }
    it { should_not be_valid }
  end

  # Position
  describe "when position is not present" do
    before { theory.position = nil }
    it { should_not be_valid }
  end
  describe "when position is negative" do
    before { theory.position = -1 }
    it { should_not be_valid }
  end
end
