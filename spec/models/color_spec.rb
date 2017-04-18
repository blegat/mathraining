# == Schema Information
#
# Table name: colors
#
#  id           :integer          not null, primary key
#  pt           :integer
#  name         :string(255)
#  color        :string(255)
#  font_color   :string(255)
#  femininename :string(255)
#

require "spec_helper"

describe Color do
  before { @color = FactoryGirl.build(:color) }

  subject { @color }

  it { should respond_to(:pt) }
  it { should respond_to(:name) }
  it { should respond_to(:femininename) }
  it { should respond_to(:color) }
  it { should respond_to(:font_color) }
  
  it { should be_valid }

  # Point
  describe "when point is not present" do
    before { @color.pt = nil }
    it { should_not be_valid }
  end
  
  # Name
  describe "when name is too long" do
    before { @color.name = "a" * 256 }
    it { should_not be_valid }
  end
  
  # Name
  describe "when feminine name is not present" do
    before { @color.femininename = "a" * 256 }
    it { should_not be_valid }
  end

  # Color
  describe "when color is not of length 7" do
    before { @color.color = "#ABCDEFG" }
    it { should_not be_valid }
  end
  
  # Font color
  describe "when font_color is of length 7" do
    before { @color.font_color = "#ABCDEF" }
    it { should be_valid }
  end

end
