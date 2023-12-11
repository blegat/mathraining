# == Schema Information
#
# Table name: extracts
#
#  id                  :integer          not null, primary key
#  externalsolution_id :integer
#  text                :string
#
require "spec_helper"

describe Extract, extract: true do
  let!(:extract) { FactoryGirl.build(:extract) }

  subject { extract }
  
  it { should be_valid }

  # Text
  describe "when text is not present" do
    before { extract.text = nil }
    it { should_not be_valid }
  end
  
  describe "when text is too long" do
    before { extract.text = "a" * 256 }
    it { should_not be_valid }
  end
end
