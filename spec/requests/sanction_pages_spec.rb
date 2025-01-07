# -*- coding: utf-8 -*-
require "spec_helper"

describe "Sanction pages", sanction: true do

  subject { page }

  let(:root) { FactoryGirl.create(:root) }
  let!(:user) { FactoryGirl.create(:user) }
  let!(:sanction) { FactoryGirl.create(:sanction, user: user) }
  let(:newreason) { "Vous êtes finalement banni jusqu'au [DATE] pour telle raison." }

  describe "root" do
    before { sign_in root }
    
    describe "visits user sanction path" do
      before { visit user_sanctions_path(user) }
      specify do
        expect(page).to have_content("Sanctionner")
        expect(page).to have_content(sanction.message)
        expect(page).to have_link("Modifier", href: edit_sanction_path(sanction))
        expect(page).to have_link("Supprimer")
        expect(page).to have_button("Créer une sanction")
        expect { click_link("Supprimer") }.to change(Sanction, :count).by(-1)
      end
    end
    
    describe "creates a sanction" do
      before { visit new_user_sanction_path(user) }
      it { should have_selector("h1", text: "Créer une sanction") }
      
      describe "and sends with good information" do
        before do
          fill_in "Message", with: newreason
          click_button "Créer"
        end
        specify do
          expect(page).to have_success_message("Sanction ajoutée")
          expect(user.sanctions.order(:id).last.reason).to eq(newreason)
        end
      end
      
      describe "and sends with wrong information" do
        before do
          fill_in "Message", with: "Mauvais raison"
          click_button "Créer"
        end
        specify do
          expect(page).to have_error_message("Le message doit contenir exactement une fois '[DATE]'")
          expect(page).to have_selector("h1", text: "Créer une sanction")
        end
      end
    end
    
    describe "edits a sanction" do
      before { visit edit_sanction_path(sanction) }
      it { should have_selector("h1", text: "Modifier une sanction") }
      
      describe "and sends with good information" do
        before do
          fill_in "Message", with: newreason
          click_button "Modifier"
          sanction.reload
        end
        specify do
          expect(page).to have_success_message("Sanction modifiée")
          expect(sanction.reason).to eq(newreason)
        end
      end
      
      describe "and sends with wrong information" do
        before do
          fill_in "Date de début", with: ""
          fill_in "Message", with: newreason
          click_button "Modifier"
          sanction.reload
        end
        specify do
          expect(page).to have_error_message("Date de début doit être rempli")
          expect(page).to have_selector("h1", text: "Modifier une sanction")
          expect(sanction.reason).to_not eq(newreason)
        end
      end
    end
  end
end
