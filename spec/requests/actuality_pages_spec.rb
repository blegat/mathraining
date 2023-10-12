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
    
    describe "visits root path" do
      before { visit root_path }
      it do
        should have_content("Actualités")
        should have_content(actuality.title)
        should have_content(actuality.content)
        should have_no_link("Modifier l'actualité")
        should have_no_link("Supprimer l'actualité")
        should have_no_button("Ajouter une actualité")
      end
    end
    
    describe "tries to create an actuality" do
      before { visit new_actuality_path }
      it { should have_content(error_access_refused) }
    end
    
    describe "tries to edit an actuality" do
      before { visit edit_actuality_path(actuality) }
      it { should have_content(error_access_refused) }
    end
  end

  describe "admin" do
    before { sign_in admin }
    
    describe "visits root path" do
      before { visit root_path }
      specify do
        expect(page).to have_content("Actualités")
        expect(page).to have_content(actuality.title)
        expect(page).to have_content(actuality.content)
        expect(page).to have_link("Modifier l'actualité", href: edit_actuality_path(actuality))
        expect(page).to have_link("Supprimer l'actualité")
        expect(page).to have_button("Ajouter une actualité")
        expect { click_link("Supprimer l'actualité") }.to change(Actuality, :count).by(-1)
      end
    end
    
    describe "creates an actuality" do
      before { visit new_actuality_path }
      it { should have_selector("h1", text: "Ajouter une actualité") }
      describe "and sends with good information" do
        before do
          fill_in "Titre", with: newtitle
          fill_in "MathInput", with: newcontent
          click_button "Créer"
        end
        specify do
          expect(Actuality.order(:id).last.title).to eq(newtitle)
          expect(Actuality.order(:id).last.content).to eq(newcontent)
        end
      end
      describe "and sends with wrong information" do
        before do
          fill_in "Titre", with: ""
          fill_in "MathInput", with: newcontent
          click_button "Créer"
        end
        specify do
          expect(page).to have_error_message("erreur")
          expect(page).to have_selector("h1", text: "Ajouter une actualité")
          expect(Actuality.order(:id).last.content).to_not eq(newcontent)
        end
      end
    end
    
    describe "edits an actuality" do
      before { visit edit_actuality_path(actuality) }
      it { should have_selector("h1", text: "Modifier une actualité") }
      describe "and sends with good information" do
        before do
          fill_in "Titre", with: newtitle
          fill_in "MathInput", with: newcontent
          click_button "Modifier"
          actuality.reload
        end
        specify do
          expect(actuality.title).to eq(newtitle)
          expect(actuality.content).to eq(newcontent)
        end
      end
      describe "and sends with wrong information" do
        before do
          fill_in "Titre", with: newtitle
          fill_in "MathInput", with: ""
          click_button "Modifier"
          actuality.reload
        end
        specify do
          expect(page).to have_error_message("erreur")
          expect(page).to have_selector("h1", text: "Modifier une actualité")
          expect(actuality.title).to_not eq(newtitle)
        end
      end
    end
    
    describe "visits an actuality that does not exist" do
      before { visit edit_actuality_path(3000) }
      it { should have_content(error_access_refused) }
    end
  end
end
