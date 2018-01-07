# -*- coding: utf-8 -*-
require "spec_helper"

describe "Chapter pages" do

  subject { page }

  let(:admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }
  let(:section) { FactoryGirl.create(:section) }
  let(:online_chapter) { FactoryGirl.create(:chapter, section: section, online: true) }
  let(:offline_chapter) { FactoryGirl.create(:chapter, section: section, online: false) }
  let(:title) { "Mon titre de chapitre" }
  let(:description) { "Ma description de chapitre" }
  let(:level) { 5 }
  let(:newtitle) { "Mon nouveau titre de chapitre" }
  let(:newdescription) { "Ma nouvelle description de chapitre" }
  let(:newlevel) { 6 }
  
  describe "visitor" do

  end

  describe "user" do
    before { sign_in user }
    
    describe "tries to create a chapter" do
      before { visit new_section_chapter_path(section) }
      it { should_not have_selector("h1", text: "Créer un chapitre") }
    end
    
    describe "tries to edit a chapter" do
      before { visit edit_chapter_path(offline_chapter) }
      it { should_not have_selector("h1", text: "Modifier") }
    end
  end

  describe "admin" do
    before { sign_in admin }
    
    describe "creates a chapter" do
      before do
        visit new_section_chapter_path(section)
        fill_in "Titre", with: title
        fill_in "MathInput", with: description
        fill_in "Niveau", with: level
      end
      specify { expect { click_button "Ajouter" }.to change(Chapter, :count).by(1) }  
    end
    
    describe "edits a chapter" do
      before do
        visit edit_chapter_path(offline_chapter)
        fill_in "Titre", with: newtitle
        fill_in "MathInput", with: newdescription
        fill_in "Niveau", with: newlevel
        click_button "Editer"
        offline_chapter.reload
      end
      specify do
        expect(offline_chapter.name).to eq(newtitle)
        expect(offline_chapter.description).to eq(newdescription)
        expect(offline_chapter.level).to eq(newlevel)
      end
    end
  end
end
