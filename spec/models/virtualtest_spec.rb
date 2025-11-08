# == Schema Information
#
# Table name: virtualtests
#
#  id       :integer          not null, primary key
#  duration :integer
#  number   :integer          default(1)
#  online   :boolean
#
require "spec_helper"

describe Virtualtest, virtualtest: true do

  let!(:virtualtest) { FactoryBot.build(:virtualtest) }

  subject { virtualtest }

  it { should be_valid }
  
  # Duration
  describe "when duration is not present" do
    before { virtualtest.duration = nil }
    it { should_not be_valid }
  end
  
  describe "when duration is zero" do
    before { virtualtest.duration = 0 }
    it { should_not be_valid }
  end

  # Number
  describe "when number is not present" do
    before { virtualtest.number = nil }
    it { should_not be_valid }
  end
  
  describe "when number is too small" do
    before { virtualtest.number = 0 }
    it { should_not be_valid }
  end
  
  describe "when number is not unique" do
    before { FactoryBot.create(:virtualtest, number: virtualtest.number) }
    it { should_not be_valid }
  end
end
