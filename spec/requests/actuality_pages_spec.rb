# -*- coding: utf-8 -*-
require "spec_helper"

describe "Actuality pages", actuality: true do

  subject { page }

  let(:admin) { FactoryGirl.create(:admin) }
  let!(:actuality) { FactoryGirl.create(:actuality) }
  let(:newtitle) { "Nouveau titre" }
  let(:newcontent) { "Nouveau contenu" }

  describe "admin" do
    before { sign_in admin }
    
    describe "visits root path" do
      before { visit root_path }
      specify do
        expect(page).to have_content("Actualités")
        expect(page).to have_link("Supprimer l'actualité")
        expect { click_link("Supprimer l'actualité") }.to change(Actuality, :count).by(-1)
      end
    end
    
    describe "creates an actuality" do
      before { visit new_actuality_path }
      it { should have_selector("h1", text: "Ajouter une actualité") }
      
      describe "with good information" do
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
      
      describe "with wrong information" do
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
      
      describe "with good information" do
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
      
      describe "with wrong information" do
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
  end
end
