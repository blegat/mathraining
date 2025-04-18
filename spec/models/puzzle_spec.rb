# == Schema Information
#
# Table name: puzzles
#
#  id          :bigint           not null, primary key
#  statement   :text
#  code        :string
#  position    :integer
#  explanation :text
#
require "spec_helper"

describe Puzzle, puzzle: true do

  let!(:puzzle) { FactoryBot.build(:puzzle) }

  subject { puzzle }

  it { should be_valid }

  # Statement
  describe "when statement is not present" do
    before { puzzle.statement = " " }
    it { should_not be_valid }
  end
  describe "when statement is too long" do
    before { puzzle.statement = "a" * 16001 }
    it { should_not be_valid }
  end

  # Position
  describe "when position is not present" do
    before { puzzle.position = nil }
    it { should_not be_valid }
  end
  describe "when position is negative" do
    before { puzzle.position = -1 }
    it { should_not be_valid }
  end

  # Code
  describe "when code is not present" do
    before { puzzle.code = nil }
    it { should_not be_valid }
  end
  describe "when code is too short" do
    before { puzzle.code = "CODE" }
    it { should_not be_valid }
  end
  describe "when code is too long" do
    before { puzzle.code = "ANSWER" }
    it { should_not be_valid }
  end
  describe "when code contains strange character" do
    before { puzzle.code = "HELLÉ" }
    it { should_not be_valid }
  end
  
  # Explication
  describe "when explanation is not present" do
    before { puzzle.explanation = " " }
    it { should_not be_valid }
  end
  describe "when explanation is too long" do
    before { puzzle.explanation = "a" * 16001 }
    it { should_not be_valid }
  end
end
