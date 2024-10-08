require "spec_helper"

describe ChaptersHelper, type: :helper, chapter: true do

  include ChaptersHelper
  
  let(:user) { FactoryGirl.create(:user) }
  let(:user_bad) { FactoryGirl.create(:user) }
  let(:admin) { FactoryGirl.create(:admin) }
  let(:section_fondation) { FactoryGirl.create(:section, fondation: true) }
  let(:section) { FactoryGirl.create(:section) }
  let!(:chapter_offline) { FactoryGirl.create(:chapter, section: section_fondation, online: false) }
  let!(:chapter_fondation) { FactoryGirl.create(:chapter, section: section_fondation, online: true) }
  let!(:chapter1) { FactoryGirl.create(:chapter, section: section, online: true) }
  let!(:chapter2) { FactoryGirl.create(:chapter, section: section, online: true) }
  
  before do
    chapter2.prerequisites << chapter1
    user.chapters << chapter1
  end

  describe "accessible chapters" do      
    it do
      expect(accessible_chapters(admin, ["id"]).map(&:id).sort).to eq([chapter_offline.id, chapter_fondation.id, chapter1.id, chapter2.id])
      expect(accessible_chapters(user, ["id"]).map(&:id).sort).to eq([chapter_fondation.id, chapter1.id, chapter2.id])
      expect(accessible_chapters(user_bad, ["id"]).map(&:id).sort).to eq([chapter_fondation.id, chapter1.id])
      expect(accessible_chapters(nil, ["id"]).map(&:id).sort).to eq([chapter_fondation.id, chapter1.id]) # not signed in
    end
  end
  
  describe "accessible chapters from section" do
    it do
      expect(accessible_chapters_from_section(admin, section_fondation, ["id"]).map(&:id).sort).to eq([chapter_offline.id, chapter_fondation.id].sort)
      expect(accessible_chapters_from_section(user, section_fondation, ["id"]).map(&:id).sort).to eq([chapter_fondation.id])
      expect(accessible_chapters_from_section(user_bad, section_fondation, ["id"]).map(&:id).sort).to eq([chapter_fondation.id])
      expect(accessible_chapters_from_section(nil, section_fondation, ["id"]).map(&:id).sort).to eq([chapter_fondation.id]) # not signed in
      
      expect(accessible_chapters_from_section(admin, section, ["id"]).map(&:id).sort).to eq([chapter1.id, chapter2.id].sort)
      expect(accessible_chapters_from_section(user, section, ["id"]).map(&:id).sort).to eq([chapter1.id, chapter2.id].sort)
      expect(accessible_chapters_from_section(user_bad, section, ["id"]).map(&:id).sort).to eq([chapter1.id])
      expect(accessible_chapters_from_section(nil, section, ["id"]).map(&:id).sort).to eq([chapter1.id]) # not signed in
    end
  end
end
