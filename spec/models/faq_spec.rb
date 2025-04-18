# == Schema Information
#
# Table name: faqs
#
#  id       :bigint           not null, primary key
#  question :text
#  answer   :text
#  position :integer
#
require "spec_helper"

describe Faq, faq: true do
  let!(:faq) { FactoryBot.create(:faq) }

  subject { faq }
  
  it { should be_valid }

  # Question
  describe "when question is not present" do
    before { faq.question = "" }
    it { should_not be_valid }
  end
  
  describe "when question is too long" do
    before { faq.question = "a" * 1001 }
    it { should_not be_valid }
  end
  
  # Answer
  describe "when answer is not present" do
    before { faq.answer = "" }
    it { should_not be_valid }
  end
  
  describe "when answer is too long" do
    before { faq.answer = "a" * 16001 }
    it { should_not be_valid }
  end

  # Position
  describe "when position is not present" do
    before { faq.position = nil }
    it { should_not be_valid }
  end
  
  describe "when position is not positive" do
    before { faq.position = 0 }
    it { should_not be_valid }
  end
end
