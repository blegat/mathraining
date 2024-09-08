# Table name: privacypolicies
#
#  id               :integer          not null, primary key
#  content          :text
#  description      :text
#  publication_time :datetime
#  online           :boolean          default(FALSE)
#
require "spec_helper"

describe Privacypolicy, privacypolicy: true do

  let!(:privacypolicy) { FactoryGirl.build(:privacypolicy) }

  subject { privacypolicy }

  it { should be_valid }

  # Content
  describe "when content is not present" do
    before { privacypolicy.content = nil }
    it { should_not be_valid }
  end
  
  describe "when content is too long" do
    before { privacypolicy.content = "a" * 32001 }
    it { should_not be_valid }
  end
  
  # Content
  describe "when description is not present" do
    before { privacypolicy.description = nil }
    it { should_not be_valid }
  end
  
  describe "when description is too long" do
    before { privacypolicy.description = "a" * 16001 }
    it { should_not be_valid }
  end
end
