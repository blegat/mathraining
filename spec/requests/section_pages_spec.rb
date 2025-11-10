# -*- coding: utf-8 -*-
require "spec_helper"

describe "Section pages", section: true do

  subject { page }

  let(:admin) { FactoryBot.create(:admin) }
  let(:user) { FactoryBot.create(:user) }
  let(:section) { FactoryBot.create(:section) }
  let(:section_fondation) { FactoryBot.create(:fondation_section) }
  let(:newtitle) { "Mon nouveau titre de section" }
  let(:newabbreviation) { "Nouv. Tit. Sec." }
  let(:newshortabbreviation) { "Nv. Tit." }
  let(:newinitials) { "NT" }
  let(:newdescription) { "Ma nouvelle description de section" }

  describe "admin" do
    before { sign_in admin }
    
    describe "visits a section that does not exist" do # to test check_nil_object
      before { visit section_path(53618) }
      it { should have_content(error_access_refused) }
    end
    
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
        fill_in "Abréviation", with: newabbreviation
        fill_in "Abréviation courte", with: newshortabbreviation
        fill_in "Initiales", with: newinitials
        fill_in "MathInput", with: newdescription
        click_button "Modifier"
        section.reload
      end
      specify do
        expect(section.name).to eq(newtitle)
        expect(section.abbreviation).to eq(newabbreviation)
        expect(section.short_abbreviation).to eq(newshortabbreviation)
        expect(section.initials).to eq(newinitials)
        expect(section.description).to eq(newdescription)
      end
    end
    
    describe "edits a section with wrong input" do
      before do
        visit edit_section_path(section)
        fill_in "Nom", with: ""
        fill_in "Abréviation", with: newabbreviation
        fill_in "Abréviation courte", with: newshortabbreviation
        fill_in "Initiales", with: newinitials
        fill_in "MathInput", with: newdescription
        click_button "Modifier"
        section.reload
      end
      specify do
        expect(page).to have_error_message("Nom doit être rempli")
        expect(section.name).not_to eq("")
        expect(section.abbreviation).not_to eq(newabbreviation)
        expect(section.short_abbreviation).not_to eq(newshortabbreviation)
        expect(section.initials).not_to eq(newinitials)
        expect(section.description).not_to eq(newdescription)
      end
    end
  end
end
