# == Schema Information
#
# Table name: sections
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  description :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  image       :string(255)
#

require 'spec_helper'

describe Section do
  before { @sec = FactoryGirl.build(:section) }

  subject { @sec }

  it { should respond_to(:name) }
  it { should respond_to(:description) }
  it { should respond_to(:chapters) }

  it { should be_valid }

  # Name
  describe "when name is not present" do
    before { @sec.name = " " }
    it { should_not be_valid }
  end
  describe "when name is too long" do
    before { @sec.name = "a" * 256 }
    it { should_not be_valid }
  end

  # Description
  describe "when description is not present" do
    before { @sec.description = " " }
    it { should be_valid }
  end
  describe "when description is too long" do
    before { @sec.description = "a" * 8001 }
    it { should_not be_valid }
  end

  # Chapters
  describe "when a chapter is added" do
    let (:chap1) { FactoryGirl.create(:chapter) }
    let (:chap2) { FactoryGirl.create(:chapter) }
    before { @sec.chapters << chap1 }
    specify { @sec.chapters.should include(chap1) }
    specify { @sec.chapters.should_not include(chap2) }
    describe "when it is added to a chapter" do
      let (:chap3) { FactoryGirl.create(:chapter) }
      before do
        @sec.save
        chap3.sections << @sec 
        @sec.reload
      end
      specify { @sec.chapters.should include(chap3) }
    end
  end
end
