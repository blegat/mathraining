# -*- coding: utf-8 -*-
require "spec_helper"

describe "Actuality pages" do

  subject { page }

  let(:admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }
  let!(:actuality) { FactoryGirl.create(:actuality) }
  let(:newtitle) { "Nouveau titre" }
  let(:newcontent) { "Nouveau contenu" }

  describe "user" do
    before { sign_in user }
    before { visit root_path }
    it { should_not have_link("Modifier l'actualité") }
    it { should_not have_link("Supprimer l'actualité") }
    
    describe "tries to create an actuality" do
      before { visit new_actuality_path }
      it { should_not have_selector("h1", text: "Ajouter") }
    end
    
    describe "tries to edit an actuality" do
      before { visit edit_actuality_path(actuality) }
      it { should_not have_selector("h1", text: "Modifier") }
    end
  end

  describe "admin" do
    before { sign_in admin }
    before { visit root_path }
    
    it { should have_link("Modifier l'actualité") }
    it { should have_link("Supprimer l'actualité") }
    
    describe "creates an actuality" do
      before { visit new_actuality_path }
      it { should have_selector("h1", text: "Ajouter") }
      describe "and sends with good information" do
        before do
          fill_in "Titre", with: newtitle
          fill_in "MathInput", with: newcontent
          click_button "Créer"
        end
        specify { expect(Actuality.order(:id).last.title).to eq(newtitle) }
        specify { expect(Actuality.order(:id).last.content).to eq(newcontent) }
      end
      describe "and sends with wrong information" do
        before do
          fill_in "Titre", with: ""
          fill_in "MathInput", with: newcontent
          click_button "Créer"
        end
        it { should have_content("erreur") }
        it { should have_selector("h1", text: "Ajouter") }
        specify { expect(Actuality.order(:id).last.content).to_not eq(newcontent) }
      end
    end
    
    describe "edits an actuality" do
      before { visit edit_actuality_path(actuality) }
      it { should have_selector("h1", text: "Modifier") }
      describe "and sends with good information" do
        before do
          fill_in "Titre", with: newtitle
          fill_in "MathInput", with: newcontent
          click_button "Modifier"
          actuality.reload
        end
        specify { expect(actuality.title).to eq(newtitle) }
        specify { expect(actuality.content).to eq(newcontent) }
      end
      describe "and sends with wrong information" do
        before do
          fill_in "Titre", with: newtitle
          fill_in "MathInput", with: ""
          click_button "Modifier"
          actuality.reload
        end
        it { should have_content("erreur") }
        it { should have_selector("h1", text: "Modifier") }
        specify { expect(actuality.title).to_not eq(newtitle) }
      end
    end
    
    describe "delete an actuality" do
      specify { expect { click_link("Supprimer l'actualité") }.to change(Actuality, :count).by(-1) }
    end
    
    describe "visit an equality that does not exist" do
      before { visit edit_actuality_path(3000) }
      it { should have_selector("div.error", text: "Cette page n'existe pas ou vous n'y avez pas accès.") }
    end
  end
end
