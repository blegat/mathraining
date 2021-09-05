# == Schema Information
#
# Table name: chapters
#
#  id               :integer          not null, primary key
#  name             :string
#  description      :text
#  level            :integer
#  created_at       :datetime
#  updated_at       :datetime
#  online           :boolean          default(FALSE)
#  section_id       :integer          default(7)
#  nb_tries         :integer          default(0)
#  nb_solved        :integer          default(0)
#  position         :integer          default(0)
#  author           :string
#  publication_time :date
#
require "spec_helper"

describe Chapter do

  before { @chap = Chapter.new(name: "Example",
                               description: "Nice example",
                               level: 1) }

  subject { @chap }

  it { should respond_to(:name) }
  it { should respond_to(:description) }
  it { should respond_to(:level) }
  it { should respond_to(:theories) }
  it { should respond_to(:questions) }
  it { should respond_to(:prerequisites) }
  it { should respond_to(:backwards) }
  it { should respond_to(:available_prerequisites) }
  it { should respond_to(:recursive_prerequisites) }

  it { should be_valid }

  # Name
  describe "when name is not present" do
    before { @chap.name = nil }
    it { should_not be_valid }
  end
  describe "when name is present" do
    before { @chap.name = "coucou" }
    it { should be_valid }
  end
  describe "when name is too long" do
    before { @chap.name = "a" * 256 }
    it { should_not be_valid }
  end
  describe "when name is already taken" do
    before do
      other_chap = Chapter.new(name: @chap.name, description: "Other description", level: 2)
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
    before { @chap.description = "a" * 16001 }
    it { should_not be_valid }
  end

  # Level
  describe "when level is 1" do
    before { @chap.level = 1 }
    it { should be_valid }
  end
  
  describe "when level is 3" do
    before { @chap.level = 3 }
    it { should be_valid }
  end
  
  describe "when level is not present" do
    before { @chap.level = nil }
    it { should_not be_valid }
  end

  describe "when level is zero" do
    before { @chap.level = 0 }
    it { should_not be_valid }
  end

  describe "when level is greater than 3" do
    before { @chap.level = 4 }
    it { should_not be_valid }
  end

  # Prerequisite
  describe "when there is a prerequisite" do
    let!(:chap1) { FactoryGirl.create(:chapter) }
    let!(:chap2) { FactoryGirl.create(:chapter) }
    let!(:chap3) { FactoryGirl.create(:chapter) }
    let!(:chap4) { FactoryGirl.create(:chapter) }
    before do
      chap1.prerequisites << chap3
      @chap.save
      @chap.prerequisites << chap1
      chap1.prerequisites << chap2
      # chap < chap1 < (chap2 & chap3)
    end
    describe "recursive_prerequisites should be correct" do
      specify { expect(@chap.recursive_prerequisites).to include(chap1.id) }
      specify { expect(@chap.recursive_prerequisites).to include(chap2.id) }
      specify { expect(@chap.recursive_prerequisites).to include(chap3.id) }
      specify { expect(@chap.recursive_prerequisites).not_to include(chap4.id) }
    end
    describe "available_prerequisites should be correct" do
      specify { expect(@chap.available_prerequisites).not_to include(chap1) }
      specify { expect(@chap.available_prerequisites).not_to include(chap2) }
      specify { expect(@chap.available_prerequisites).not_to include(chap3) }
      specify { expect(@chap.available_prerequisites).to include(chap4) }
    end
  end

end
