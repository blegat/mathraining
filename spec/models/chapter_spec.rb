# == Schema Information
#
# Table name: chapters
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  description :text
#  level       :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'spec_helper'

describe User do

  before { @chap = Chapter.new(name: "Example",
                               description: "Nice example",
                               level: 1) }

  subject { @chap }

  it { should respond_to(:name) }
  it { should respond_to(:description) }
  it { should respond_to(:level) }
  it { should respond_to(:theories) }
  it { should respond_to(:prerequisites) }
  it { should respond_to(:backwards) }
  it { should respond_to(:available_prerequisites) }
  it { should respond_to(:recursive_prerequisites) }

  it { should be_valid }

  # Name
  describe "when name is not present" do
    before { @chap.name = " " }
    it { should_not be_valid }
  end
  describe "when name is too long" do
    before { @chap.name = "a" * 256 }
    it { should_not be_valid }
  end
  describe "when name is already taken" do
    before do
      other_chap = Chapter.new(name: @chap.name,
                               description: "Other description",
                               level: (@chap.level + 1) % 10)
      other_chap.save
    end
    it { should_not be_valid }
  end

  # Description
  describe "when description is not present" do
    before { @chap.description = nil }
    it { should be_valid }
  end
  describe "when description is too long" do
    before { @chap.description = "a" * 8001 }
    it { should_not be_valid }
  end

  # Level
  describe "when level is not present" do
    before { @chap.level = nil }
    it { should_not be_valid }
  end

  describe "when level is 0" do
    before { @chap.level = 0 }
    it { should be_valid }
  end

  describe "when level is 10" do
    before { @chap.level = 10 }
    it { should be_valid }
  end

  describe "when level is negative" do
    before { @chap.level = -1 }
    it { should_not be_valid }
  end

  describe "when level is greater than 10" do
    before { @chap.level = 11 }
    it { should_not be_valid }
  end

  # Prerequisite
  describe "when there is a prerequisite" do
    let(:chap1) { FactoryGirl.create(:chapter) }
    let(:chap2) { FactoryGirl.create(:chapter) }
    let(:chap3) { FactoryGirl.create(:chapter) }
    let(:chap4) { FactoryGirl.create(:chapter) }
    before do
      chap1.prerequisites << chap3
      @chap.save
      @chap.prerequisites << chap1
      chap1.prerequisites << chap2
    end
    describe "recursive_prerequisites should be correct" do
      specify { @chap.recursive_prerequisites.should include(chap1.id) }
      specify { @chap.recursive_prerequisites.should include(chap2.id) }
      specify { @chap.recursive_prerequisites.should include(chap3.id) }
      specify { @chap.recursive_prerequisites.should_not include(chap4.id) }
    end
    describe "available_prerequisites should be correct" do
      specify { @chap.available_prerequisites.should_not include(chap1) }
      specify { @chap.available_prerequisites.should_not include(chap2) }
      specify { @chap.available_prerequisites.should_not include(chap3) }
      specify { @chap.available_prerequisites.should include(chap4) }
    end
  end

end
