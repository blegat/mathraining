# == Schema Information
#
# Table name: links
#
#  id            :integer          not null, primary key
#  discussion_id :integer
#  user_id       :integer
#  nonread       :integer
#
require "spec_helper"

describe Link, link: true do
  let!(:user) { FactoryGirl.create(:user) }
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
