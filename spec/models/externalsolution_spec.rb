# == Schema Information
#
# Table name: externalsolutions
#
#  id         :integer          not null, primary key
#  problem_id :integer
#  url        :text
#
require "spec_helper"

describe Externalsolution, externalsolution: true do
  let!(:externalsolution) { FactoryGirl.build(:externalsolution) }

  subject { externalsolution }
  
  it { should be_valid }

  # Url
  describe "when url is not present" do
    before { externalsolution.url = nil }
    it { should_not be_valid }
  end
  
  describe "when url is too long" do
    before { externalsolution.url = "a" * 1001 }
    it { should_not be_valid }
  end
end
