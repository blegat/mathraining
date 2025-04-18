# == Schema Information
#
# Table name: corrections
#
#  id            :integer          not null, primary key
#  user_id       :integer
#  submission_id :integer
#  content       :text
#  created_at    :datetime         not null
#
require "spec_helper"

describe Correction do
  let!(:correction) { FactoryBot.build(:correction) }

  subject { correction }

  it { should be_valid }

  # Content
  describe "when content is not present" do
    before { correction.content = " " }
    it { should_not be_valid }
  end
  
  describe "when content is too long" do
    before { correction.content = "a" * 16001 }
    it { should_not be_valid }
  end
end
