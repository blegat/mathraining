# == Schema Information
#
# Table name: colors
#
#  id           :integer          not null, primary key
#  pt           :integer
#  name         :string
#  color        :string
#  femininename :string
#  dark_color   :string
#
require "spec_helper"

describe Color, color: true do
  let!(:color) { FactoryGirl.build(:color) }

  subject { color }
  
  it { should be_valid }

  # Point
  describe "when point is not present" do
    before { color.pt = nil }
    it { should_not be_valid }
  end
  
  # Name
  describe "when name is too long" do
    before { color.name = "a" * 256 }
    it { should_not be_valid }
  end
  
  # Feminine name
  describe "when feminine name is not present" do
    before { color.femininename = "a" * 256 }
    it { should_not be_valid }
  end

  # Color
  describe "when color is not of length 7" do
    before { color.color = "#ABCDEFG" }
    it { should_not be_valid }
  end
  
  # Dark color
  describe "when dark color is not of length 7" do
    before { color.color = "#ABCDE" }
    it { should_not be_valid }
  end
end
