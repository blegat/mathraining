# == Schema Information
#
# Table name: exercises
#
#  id         :integer          not null, primary key
#  statement  :text
#  decimal    :boolean          default(FALSE)
#  answer     :float
#  chapter_id :integer
#  position   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  online     :boolean          default(FALSE)
#

require 'spec_helper'

describe Exercise do
  before { @ex = FactoryGirl.build(:exercise) }

  subject { @ex }

  it { should respond_to(:statement) }
  it { should respond_to(:position) }
  it { should respond_to(:chapter) }
  it { should respond_to(:decimal) }
  it { should respond_to(:answer) }
  it { should respond_to(:online) }

  it { should be_valid }

  # Statement
  describe "when statement is not present" do
    before { @ex.statement = " " }
    it { should_not be_valid }
  end
  describe "when statement is too long" do
    before { @ex.statement = "a" * 8001 }
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
  describe "when position is already taken with the same chapter" do
    before { FactoryGirl.create(:exercise,
                                chapter: @ex.chapter,
                                position: @ex.position) }
    it { should_not be_valid }
  end
  describe "when position is already taken with a different chapter" do
    before { FactoryGirl.create(:exercise,
                                position: @ex.position) }
    it { should be_valid }
  end

  # Decimal
  describe "when decimal is not present" do
    before { @ex.decimal = nil }
    it { should_not be_valid }
  end

  # Answer
  describe "when answer is not present" do
    before { @ex.answer = nil }
    it { should_not be_valid }
  end
end
