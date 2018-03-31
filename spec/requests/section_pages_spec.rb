# -*- coding: utf-8 -*-
require "spec_helper"

describe "Section pages" do

  subject { page }

  let(:admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }
  let(:section) { FactoryGirl.create(:section) }
  let(:newtitle) { "Mon nouveau titre de section" }
  let(:newdescription) { "Ma nouvelle description de section" }

  describe "user" do
    before { sign_in user }
    
    describe "tries to edit a section" do
      before { visit edit_section_path(section) }
      it { should_not have_selector("h1", text: "Modifier") }
    end
  end

  describe "admin" do
    before { sign_in admin }
    
    describe "edits a section" do
      before do
        visit edit_section_path(section)
        fill_in "Nom", with: newtitle
        fill_in "MathInput", with: newdescription
        click_button "Éditer"
        section.reload
      end
      specify { expect(section.name).to eq(newtitle) }
      specify { expect(section.description).to eq(newdescription) }
    end
  end
end
