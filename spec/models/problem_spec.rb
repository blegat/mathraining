# == Schema Information
#
# Table name: problems
#
#  id             :integer          not null, primary key
#  statement      :text
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  online         :boolean          default(FALSE)
#  level          :integer
#  explanation    :text             default("")
#  section_id     :integer
#  number         :integer          default(1)
#  virtualtest_id :integer          default(0)
#  position       :integer          default(0)
#  origin         :string
#  markscheme     :text             default("")
#
require "spec_helper"

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
    before { @p.statement = "a" * 16001 }
    it { should_not be_valid }
  end

end
