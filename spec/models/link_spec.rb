# == Schema Information
#
# Table name: links
#
#  id            :integer          not null, primary key
#  nonread       :integer
#  discussion_id :integer
#  user_id       :integer
#
# Indexes
#
#  index_links_on_discussion_id              (discussion_id)
#  index_links_on_user_id                    (user_id)
#  index_links_on_user_id_and_discussion_id  (user_id,discussion_id) UNIQUE
#
require "spec_helper"

describe Link, link: true do
  let!(:user) { FactoryBot.create(:user) }
  let!(:discussion) { Discussion.create }
  let!(:link) { Link.create(:user => user, :discussion => discussion, :nonread => 0) }

  subject { link }

  it { should be_valid }

  # Nonread
  describe "when nonread is not present" do
    before { link.nonread = nil }
    it { should_not be_valid }
  end
  
  describe "when nonread is negative" do
    before { link.nonread = -1 }
    it { should_not be_valid }
  end
end
