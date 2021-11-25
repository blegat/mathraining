# -*- coding: utf-8 -*-
require "spec_helper"

describe "Section pages" do

  subject { page }

  let(:admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }
  let(:section) { FactoryGirl.create(:section) }
  let(:section_fondation) { FactoryGirl.create(:fondation_section) }
  let(:newtitle) { "Mon nouveau titre de section" }
  let(:newdescription) { "Ma nouvelle description de section" }
  
  describe "visitor" do
    describe "visits a section" do
      before { visit section_path(section) }
      it do
        should have_selector("h1", text: section.name)
        should have_no_link("Modifier l'introduction")
        should have_no_button("Ajouter un chapitre")
      end
    end
    
    describe "visits the fondation section" do
      before { visit section_path(section_fondation) }
      it { should have_selector("h1", text: section_fondation.name) }
    end
  end

  describe "user" do
    before { sign_in user }
    
    describe "tries to edit a section" do
      before { visit edit_section_path(section) }
      it { should have_content(error_access_refused) }
    end
  end

  describe "admin" do
    before { sign_in admin }
    
    describe "visits a section" do
      before { visit section_path(section) }
      it do
        should have_selector("h1", text: section.name)
        should have_link("Modifier l'introduction")
        should have_link("Ajouter un chapitre")
      end
    end
    
    describe "edits a section" do
      before do
        visit edit_section_path(section)
        fill_in "Nom", with: newtitle
        fill_in "MathInput", with: newdescription
        click_button "Modifier"
        section.reload
      end
      specify do
        expect(section.name).to eq(newtitle)
        expect(section.description).to eq(newdescription)
      end
    end
  end
end
