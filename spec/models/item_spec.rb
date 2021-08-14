# == Schema Information
#
# Table name: items
#
#  id          :integer          not null, primary key
#  ans         :string
#  ok          :boolean          default(FALSE)
#  question_id :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  position    :integer
#
require "spec_helper"

describe Item do
  before { @c = FactoryGirl.build(:item) }

  subject { @c }

  it { should respond_to(:question) }
  it { should respond_to(:ans) }
  it { should respond_to(:ok) }

  it { should be_valid }

  # Qcm
  describe "when question is not present" do
    before { @c.question = nil }
    it { should_not be_valid }
  end

  # Ans
  describe "when ans is not present" do
    before { @c.ans = " " }
    it { should_not be_valid }
  end
  describe "when ans is too long" do
    before { @c.ans = "a" * 256 }
    it { should_not be_valid }
  end

  # Ok
  describe "when ok is not present" do
    before { @c.ok = nil }
    it { should_not be_valid }
  end

end
