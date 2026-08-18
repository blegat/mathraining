# == Schema Information
#
# Table name: extracts
#
#  id                  :bigint           not null, primary key
#  text                :string
#  externalsolution_id :bigint
#
# Indexes
#
#  index_extracts_on_externalsolution_id  (externalsolution_id)
#
require "spec_helper"

describe Extract, extract: true do
  let!(:extract) { FactoryBot.build(:extract) }

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
