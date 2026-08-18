# == Schema Information
#
# Table name: tchatmessages
#
#  id            :integer          not null, primary key
#  content       :text
#  created_at    :datetime
#  discussion_id :integer
#  user_id       :integer
#
# Indexes
#
#  index_tchatmessages_on_discussion_id                 (discussion_id)
#  index_tchatmessages_on_discussion_id_and_created_at  (discussion_id,created_at) UNIQUE
#  index_tchatmessages_on_user_id                       (user_id)
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
