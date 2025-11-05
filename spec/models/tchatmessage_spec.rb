# == Schema Information
#
# Table name: tchatmessages
#
#  id            :integer          not null, primary key
#  content       :text
#  user_id       :integer
#  discussion_id :integer
#  created_at    :datetime
#
require "spec_helper"

describe Tchatmessage, discussion: true do
  let!(:user) { FactoryBot.create(:user) }
  let!(:user2) { FactoryBot.create(:user) }
  let!(:discussion) { create_discussion_between(user, user2, "Bonjour", "Coucou") }
  let!(:tchatmessage) { FactoryBot.build(:tchatmessage, discussion: discussion, user: user) }

  subject { tchatmessage }

  it { should be_valid }

  # Content
  describe "when content is not present" do
    before { tchatmessage.content = nil }
    it { should_not be_valid }
  end
  
  describe "when content is too long" do
    before { tchatmessage.content = "a" * 16001 }
    it { should_not be_valid }
  end
end
