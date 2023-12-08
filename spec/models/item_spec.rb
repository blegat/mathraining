# == Schema Information
#
# Table name: items
#
#  id          :integer          not null, primary key
#  ans         :string
#  ok          :boolean          default(FALSE)
#  question_id :integer
#  position    :integer
#
require "spec_helper"

describe Item, item: true do
  let!(:item) { FactoryGirl.build(:item) }

  subject { item }

  it { should be_valid }

  # Ans
  describe "when ans is not present" do
    before { item.ans = " " }
    it { should_not be_valid }
  end
  
  describe "when ans is too long" do
    before { item.ans = "a" * 256 }
    it { should_not be_valid }
  end

  # Ok
  describe "when ok is not present" do
    before { item.ok = nil }
    it { should_not be_valid }
  end
  
  # Position
  describe "when position is not present" do
    before { item.position = nil }
    it { should_not be_valid }
  end

end
