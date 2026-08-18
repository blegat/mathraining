# == Schema Information
#
# Table name: puzzleattempts
#
#  id        :bigint           not null, primary key
#  code      :string
#  puzzle_id :bigint
#  user_id   :bigint
#
# Indexes
#
#  index_puzzleattempts_on_puzzle_id              (puzzle_id)
#  index_puzzleattempts_on_user_id                (user_id)
#  index_puzzleattempts_on_user_id_and_puzzle_id  (user_id,puzzle_id) UNIQUE
#
require "spec_helper"

describe Puzzleattempt, puzzle: true do

  let!(:puzzleattempt) { FactoryBot.build(:puzzleattempt) }

  subject { puzzleattempt }

  it { should be_valid }

  # Code
  describe "when code is not present" do
    before { puzzleattempt.code = nil }
    it { should_not be_valid }
  end
  describe "when code is too short" do
    before { puzzleattempt.code = "CODE" }
    it { should_not be_valid }
  end
  describe "when code is too long" do
    before { puzzleattempt.code = "ANSWER" }
    it { should_not be_valid }
  end
  describe "when code contains strange character" do
    before { puzzleattempt.code = "HELL@" }
    it { should_not be_valid }
  end
end
