require "spec_helper"

describe ChaptersHelper, type: :helper, chapter: true do

  include ChaptersHelper
  
  let(:user) { FactoryBot.create(:user) }
  let(:user_bad) { FactoryBot.create(:user) }
  let(:admin) { FactoryBot.create(:admin) }
  let(:section_fondation) { FactoryBot.create(:section, fondation: true) }
  let(:section) { FactoryBot.create(:section) }
  let!(:chapter_offline) { FactoryBot.create(:chapter, section: section_fondation, online: false) }
  let!(:chapter_fondation) { FactoryBot.create(:chapter, section: section_fondation, online: true) }
  let!(:chapter1) { FactoryBot.create(:chapter, section: section, online: true) }
  let!(:chapter2) { FactoryBot.create(:chapter, section: section, online: true) }
  
  before do
    chapter2.prerequisites << chapter1
    user.chapters << chapter1
  end

  describe "non-accessible chapters" do      
    it do
      expect(non_accessible_chapters_ids(admin)).to eq(Set.new)
      expect(non_accessible_chapters_ids(user)).to eq(Set[chapter_offline.id])
      expect(non_accessible_chapters_ids(user_bad)).to eq(Set[chapter_offline.id, chapter2.id])
      expect(non_accessible_chapters_ids(nil)).to eq(Set[chapter_offline.id, chapter2.id]) # not signed in
    end
  end
  
  describe "non-accessible chapters from section" do
    it do
      expect(non_accessible_chapters_ids(admin, section_fondation)).to eq(Set.new)
      expect(non_accessible_chapters_ids(user, section_fondation)).to eq(Set[chapter_offline.id])
      expect(non_accessible_chapters_ids(user_bad, section_fondation)).to eq(Set[chapter_offline.id])
      expect(non_accessible_chapters_ids(nil, section_fondation)).to eq(Set[chapter_offline.id]) # not signed in
      
      expect(non_accessible_chapters_ids(admin, section)).to eq(Set.new)
      expect(non_accessible_chapters_ids(user, section)).to eq(Set.new)
      expect(non_accessible_chapters_ids(user_bad, section)).to eq(Set[chapter2.id])
      expect(non_accessible_chapters_ids(nil, section)).to eq(Set[chapter2.id]) # not signed in
    end
  end
end
