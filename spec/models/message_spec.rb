# == Schema Information
#
# Table name: messages
#
#  id         :integer          not null, primary key
#  content    :text
#  subject_id :integer
#  user_id    :integer
#  created_at :datetime         not null
#
require "spec_helper"

describe Message, message: true do

  let!(:message) { FactoryGirl.build(:message) }

  subject { message }

  it { should be_valid }

  # Content
  describe "when content is not present" do
    before { message.content = nil }
    it { should_not be_valid }
  end
  
  describe "when content is too long" do
    before { message.content = "a" * 16001 }
    it { should_not be_valid }
  end

  # User
  describe "when user is not present" do
    before { message.user_id = nil }
    it { should_not be_valid }
  end
  
  describe "when user is zero (automatic message)" do
    before { message.user_id = 0 }
    it { should be_valid }
  end

end
