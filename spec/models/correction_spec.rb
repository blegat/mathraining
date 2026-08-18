# == Schema Information
#
# Table name: corrections
#
#  id            :integer          not null, primary key
#  content       :text
#  created_at    :datetime         not null
#  submission_id :integer
#  user_id       :integer
#
# Indexes
#
#  index_corrections_on_submission_id  (submission_id)
#  index_corrections_on_user_id        (user_id)
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
