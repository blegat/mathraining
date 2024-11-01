# == Schema Information
#
# Table name: questions
#
#  id               :integer          not null, primary key
#  statement        :text
#  is_qcm           :boolean
#  decimal          :boolean          default(FALSE)
#  answer           :float
#  many_answers     :boolean          default(FALSE)
#  chapter_id       :integer
#  position         :integer
#  online           :boolean          default(FALSE)
#  explanation      :text
#  level            :integer          default(1)
#  nb_first_guesses :integer          default(0)
#  nb_correct       :integer          default(0)
#  nb_wrong         :integer          default(0)
#
require "spec_helper"

describe Question, question: true do

  let!(:question) { FactoryGirl.build(:question) }

  subject { question }

  it { should be_valid }

  # Statement
  describe "when statement is not present" do
    before { question.statement = " " }
    it { should_not be_valid }
  end
  describe "when statement is too long" do
    before { question.statement = "a" * 16001 }
    it { should_not be_valid }
  end

  # Position
  describe "when position is not present" do
    before { question.position = nil }
    it { should_not be_valid }
  end
  describe "when position is negative" do
    before { question.position = -1 }
    it { should_not be_valid }
  end

  # Answer
  describe "when answer is not present" do
    before { question.answer = nil }
    it { should_not be_valid }
  end

  # Explanation
  describe "when explication is not present" do
    before { question.explanation = nil }
    it { should_not be_valid }
  end

  # Level
  describe "when level is > 4" do
    before { question.level = 5 }
    it { should_not be_valid }
  end
  describe "when level is 4" do
    before { question.level = 4 }
    it { should be_valid }
  end
  
  # Value
  describe "value" do
    before { question.level = 3 }
    specify { expect(question.value).to eq(question.level * 3) }
  end
end
