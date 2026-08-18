# == Schema Information
#
# Table name: savedreplies
#
#  id         :bigint           not null, primary key
#  approved   :boolean
#  content    :text
#  nb_uses    :integer          default(0)
#  problem_id :bigint
#  section_id :bigint
#  user_id    :bigint
#
# Indexes
#
#  index_savedreplies_on_approved    (approved)
#  index_savedreplies_on_problem_id  (problem_id)
#  index_savedreplies_on_section_id  (section_id)
#  index_savedreplies_on_user_id     (user_id)
#
require "spec_helper"

describe Savedreply, savedreply: true do

  let!(:savedreply) { FactoryBot.build(:savedreply) }

  subject { savedreply }

  it { should be_valid }
  
  # Section
  describe "when section_id is not present" do
    before { savedreply.section_id = nil }
    it { should_not be_valid }
  end
  
  # Problem
  describe "when problem_id is not present" do
    before { savedreply.problem_id = nil }
    it { should_not be_valid }
  end

  # Content
  describe "when content is not present" do
    before { savedreply.content = nil }
    it { should_not be_valid }
  end
  describe "when content is too long" do
    before { savedreply.content = "A" * 16001 }
    it { should_not be_valid }
  end
  
  # Number of uses
  describe "when nb_uses is not present" do
    before { savedreply.nb_uses = nil }
    it { should_not be_valid }
  end
  describe "when nb_uses is negative" do
    before { savedreply.nb_uses = -1 }
    it { should_not be_valid }
  end
end
