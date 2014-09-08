# == Schema Information
#
# Table name: problems
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  statement  :text
#  chapter_id :integer
#  position   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  online     :boolean          default(FALSE)
#

require 'spec_helper'

describe Problem do
  before { @p = FactoryGirl.build(:problem) }

  subject { @p }

  it { should respond_to(:statement) }
  it { should respond_to(:position) }
  it { should respond_to(:online) }

  it { should be_valid }

  # Statement
  describe "when statement is not present" do
    before { @p.statement = " " }
    it { should_not be_valid }
  end
  describe "when statement is too long" do
    before { @p.statement = "a" * 8001 }
    it { should_not be_valid }
  end

end
