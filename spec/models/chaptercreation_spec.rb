# == Schema Information
#
# Table name: chaptercreations
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  chapter_id :integer
#
require "spec_helper"

describe Chaptercreation, chapter: true do
  let!(:user) { FactoryGirl.create(:user) }
  let!(:chapter) { FactoryGirl.create(:chapter) }
  let!(:chaptercreation) { Chaptercreation.new(chapter: chapter, user: user) }

  subject { chaptercreation }

  it { should be_valid }

  # Uniqueness
  describe "when already present" do
    before { Chaptercreation.create(chapter: chapter, user: user) }
    it { should_not be_valid }
  end
end
