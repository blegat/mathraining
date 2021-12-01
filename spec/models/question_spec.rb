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
#  nb_tries         :integer          default(0)
#  nb_first_guesses :integer          default(0)
#
require "spec_helper"

describe Question do
  before { @ex = FactoryGirl.build(:question) }

  subject { @ex }

  it { should respond_to(:statement) }
  it { should respond_to(:position) }
  it { should respond_to(:chapter) }
  it { should respond_to(:many_answers) }
  it { should respond_to(:decimal) }
  it { should respond_to(:answer) }
  it { should respond_to(:online) }
  it { should respond_to(:explanation) }
  it { should respond_to(:level) }

  it { should be_valid }

  # Statement
  describe "when statement is not present" do
    before { @ex.statement = " " }
    it { should_not be_valid }
  end
  describe "when statement is too long" do
    before { @ex.statement = "a" * 16001 }
    it { should_not be_valid }
  end

  # Position
  describe "when position is not present" do
    before { @ex.position = nil }
    it { should_not be_valid }
  end
  describe "when position is negative" do
    before { @ex.position = -1 }
    it { should_not be_valid }
  end

  # Answer
  describe "when answer is not present" do
    before { @ex.answer = nil }
    it { should_not be_valid }
  end

  # Explanation
  describe "when explication is not present" do
    before { @ex.explanation = nil }
    it { should be_valid }
  end

  # Level
  describe "when level is > 4" do
    before { @ex.level = 5 }
    it { should_not be_valid }
  end
  describe "when level is 4" do
    before { @ex.level = 4 }
    it { should be_valid }
  end
end
