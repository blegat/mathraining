# == Schema Information
#
# Table name: sections
#
#  id                 :integer          not null, primary key
#  name               :string
#  description        :text
#  fondation          :boolean          default(FALSE)
#  max_score          :integer          default(0)
#  abbreviation       :string
#  short_abbreviation :string
#  initials           :string
#
require "spec_helper"

describe Section, section: true do
  let(:section) { FactoryBot.build(:section) }

  subject { section }

  it { should be_valid }

  # Name
  describe "when name is not present" do
    before { section.name = " " }
    it { should_not be_valid }
  end
  describe "when name is too long" do
    before { section.name = "a" * 256 }
    it { should_not be_valid }
  end

  # Description
  describe "when description is not present" do
    before { section.description = " " }
    it { should be_valid }
  end
  describe "when description is too long" do
    before { section.description = "a" * 16001 }
    it { should_not be_valid }
  end

  # Abbreviation
  describe "when abbreviation is not present" do
    before { section.abbreviation = "" }
    it { should_not be_valid }
  end
  describe "when abbreviation is too long" do
    before { section.abbreviation = "THEORIE DES NOMBRES" }
    it { should_not be_valid }
  end
  
  # Short abbreviation
  describe "when short_abbreviation is not present" do
    before { section.short_abbreviation = "" }
    it { should_not be_valid }
  end
  describe "when short_abbreviation is too long" do
    before { section.short_abbreviation = "Th D. Nbs." }
    it { should_not be_valid }
  end
  
  # Initials
  describe "when initials is not present" do
    before { section.initials = "" }
    it { should_not be_valid }
  end
  describe "when initials is too long" do
    before { section.initials = "TDNB" }
    it { should_not be_valid }
  end
end
