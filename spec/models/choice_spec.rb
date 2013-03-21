# == Schema Information
#
# Table name: choices
#
#  id         :integer          not null, primary key
#  ans        :string(255)
#  ok         :boolean          default(FALSE)
#  qcm_id     :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'spec_helper'

describe Choice do
  before { @c = FactoryGirl.build(:choice) }

  subject { @c }

  it { should respond_to(:qcm) }
  it { should respond_to(:ans) }
  it { should respond_to(:ok) }

  it { should be_valid }

  # Qcm
  describe "when qcm is not present" do
    before { @c.qcm = nil }
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
