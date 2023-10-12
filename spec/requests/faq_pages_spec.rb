# -*- coding: utf-8 -*-
require "spec_helper"

describe "Faq pages" do

  subject { page }

  let(:admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }
  let!(:faq) { FactoryGirl.create(:faq, position: 1) }
  let(:newquestion) { "Nouvelle question" }
  let(:newanswer) { "Nouvelle réponse" }

  describe "user" do
    before { sign_in user }
    
    describe "visits faq path" do
      before { visit faqs_path }
      it do
        should have_content("Questions fréquemment posées")
        should have_content(faq.question)
        should have_content(faq.answer)
        should have_no_link("Modifier la question")
        should have_no_link("Supprimer la question")
        should have_no_button("Ajouter une question")
      end
    end
    
    describe "tries to create a question" do
      before { visit new_faq_path }
      it { should have_content(error_access_refused) }
    end
    
    describe "tries to edit a question" do
      before { visit edit_faq_path(faq) }
      it { should have_content(error_access_refused) }
    end
  end

  describe "admin" do
    before { sign_in admin }
    
    describe "visits faq path" do
      before { visit faqs_path }
      specify do
        expect(page).to have_content("Questions fréquemment posées")
        expect(page).to have_content(faq.question)
        expect(page).to have_content(faq.answer)
        expect(page).to have_link("Modifier la question", href: edit_faq_path(faq))
        expect(page).to have_link("Supprimer la question")
        expect(page).to have_no_link("haut") # Because only one question
        expect(page).to have_no_link("bas") # Because only one question
        expect(page).to have_button("Ajouter une question")
        expect { click_link("Supprimer la question") }.to change(Faq, :count).by(-1)
      end
    end
    
    describe "visits faq path with 2 questions" do
      let!(:faq2) { FactoryGirl.create(:faq, question: "Ma question", answer: "Ma réponse", position: 2) }
      before { visit faqs_path }
      specify do
        expect(page).to have_no_link("haut", href: faq_order_minus_path(faq))
        expect(page).to have_link("bas", href: faq_order_plus_path(faq))
        expect(page).to have_link("haut", href: faq_order_minus_path(faq2))
        expect(page).to have_no_link("bas", href: faq_order_plus_path(faq2))
      end
      
      describe "and move first question down" do
        before do
          click_link("bas")
          faq.reload
          faq2.reload
        end
        specify do
          expect(faq.position).to eq(2)
          expect(faq2.position).to eq(1)
        end
      end
      
      describe "and move second question up" do
        before do
          click_link("haut")
          faq.reload
          faq2.reload
        end
        specify do
          expect(faq.position).to eq(2)
          expect(faq2.position).to eq(1)
        end
      end
    end
    
    describe "creates a question" do
      before { visit new_faq_path }
      it { should have_selector("h1", text: "Ajouter une question") }
      describe "and sends with good information" do
        before do
          fill_in "Question", with: newquestion
          fill_in "MathInput", with: newanswer
          click_button "Créer"
        end
        specify do
          expect(Faq.order(:id).last.question).to eq(newquestion)
          expect(Faq.order(:id).last.answer).to eq(newanswer)
        end
      end
      describe "and sends with wrong information" do
        before do
          fill_in "Question", with: ""
          fill_in "MathInput", with: newanswer
          click_button "Créer"
        end
        specify do
          expect(page).to have_error_message("erreur")
          expect(page).to have_selector("h1", text: "Ajouter une question")
          expect(Faq.order(:id).last.answer).to_not eq(newanswer)
        end
      end
    end
    
    describe "edits a question" do
      before { visit edit_faq_path(faq) }
      it { should have_selector("h1", text: "Modifier une question") }
      describe "and sends with good information" do
        before do
          fill_in "Question", with: newquestion
          fill_in "MathInput", with: newanswer
          click_button "Modifier"
          faq.reload
        end
        specify do
          expect(faq.question).to eq(newquestion)
          expect(faq.answer).to eq(newanswer)
        end
      end
      describe "and sends with wrong information" do
        before do
          fill_in "Question", with: ""
          fill_in "MathInput", with: newanswer
          click_button "Modifier"
          faq.reload
        end
        specify do
          expect(page).to have_error_message("erreur")
          expect(page).to have_selector("h1", text: "Modifier une question")
          expect(faq.answer).to_not eq(newanswer)
        end
      end
    end
  end
end
