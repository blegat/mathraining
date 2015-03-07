# == Schema Information
#
# Table name: qcms
#
#  id           :integer          not null, primary key
#  statement    :text
#  many_answers :boolean
#  chapter_id   :integer
#  position     :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  online       :boolean          default(FALSE)
#

require 'spec_helper'

describe Qcm do
  before { @qcm = FactoryGirl.build(:qcm) }

  subject { @qcm }

  it { should respond_to(:statement) }
  it { should respond_to(:position) }
  it { should respond_to(:chapter) }

  it { should be_valid }

  # Statement
  describe "when statement is not present" do
    before { @qcm.statement = " " }
    it { should_not be_valid }
  end
  describe "when statement is too long" do
    before { @qcm.statement = "a" * 8001 }
    it { should_not be_valid }
  end

  # Position
  describe "when position is not present" do
    before { @qcm.position = nil }
    it { should_not be_valid }
  end
  describe "when position is negative" do
    before { @qcm.position = -1 }
    it { should_not be_valid }
  end
end
