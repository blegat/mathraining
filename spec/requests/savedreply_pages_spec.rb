# -*- coding: utf-8 -*-
require "spec_helper"

describe "Savedreply pages", savedreply: true do

  subject { page }

  let(:root) { FactoryGirl.create(:root) }
  let!(:problem) { FactoryGirl.create(:problem, online: true) }
  let!(:submission) { FactoryGirl.create(:submission, problem: problem, status: :waiting) }
  let!(:savedreply) { FactoryGirl.create(:savedreply, problem: problem, content: "Es-tu sûr[e] de toi ?") }
  let!(:savedreply_generic) { FactoryGirl.create(:savedreply, problem_id: 0) }
  let(:newcontent) { "Es-tu certain que $1$ est un nombre premier ?" }

  describe "root" do
    before { sign_in root }
    
    describe "visits submission" do
      before { visit problem_path(problem, :sub => submission) }
      specify do
        expect(page).to have_link("1 réponse générique")
        expect(page).to have_link("1 réponse spécifique")
        expect(page).to have_link("Ajouter", href: new_savedreply_path(:sub => submission))
      end
      
      describe "and deletes a saved reply", :js => true do
        before do
          click_link "1 réponse spécifique"
        end
        specify { expect { click_link("Supprimer", href: savedreply_path(savedreply)) }.to change(Savedreply, :count).by(-1) }
      end
      
      describe "and uses a saved reply", :js => true do
        before do
          click_button "Réserver cette soumission"
          click_link "1 réponse spécifique"
          find("#savedreply-#{savedreply.id}").click() # This registers in a hidden field that the saved reply has been used
          click_button "Poster et refuser la soumission"
          savedreply.reload
          savedreply_generic.reload
        end
        specify do
          expect(page).to have_success_message("Soumission marquée comme incorrecte")
          expect(submission.corrections.first.content).to eq("Es-tu sûr de toi ?")
          expect(savedreply.nb_uses).to eq(1)
          expect(savedreply_generic.nb_uses).to eq(0)
        end
      end
    end
    
    describe "creates a saved reply" do
      before { visit new_savedreply_path(:sub => submission) }
      it { should have_selector("h1", text: "Créer une réponse") }
      
      describe "and sends with good information" do
        before do
          fill_in "Réponse", with: newcontent
          click_button "Créer"
        end
        specify do
          expect(page).to have_success_message("Réponse ajoutée")
          expect(page).to have_selector("h1", text: "Problème ##{problem.number}")
          expect(page).to have_content(submission.content)
          expect(page).to have_link("2 réponses spécifiques")
          expect(problem.savedreplies.order(:id).last.content).to eq(newcontent)
        end
      end
      
      describe "and sends with wrong information" do
        before do
          fill_in "Réponse", with: ""
          click_button "Créer"
        end
        specify do
          expect(page).to have_error_message("Réponse doit être rempli")
          expect(page).to have_selector("h1", text: "Créer une réponse")
        end
      end
    end
    
    describe "edits a specific saved reply" do
      before { visit edit_savedreply_path(savedreply, :sub => submission) }
      it { should have_selector("h1", text: "Modifier une réponse") }
      
      describe "and makes it generic" do
        before do
          select "Aucun problème", from: "Problème"
          fill_in "Réponse", with: newcontent
          click_button "Modifier"
          savedreply.reload
        end
        specify do
          expect(page).to have_success_message("Réponse modifiée")
          expect(page).to have_selector("h1", text: "Problème ##{problem.number}")
          expect(page).to have_content(submission.content)
          expect(page).to have_link("2 réponses génériques")
          expect(savedreply.problem_id).to eq(0)
          expect(savedreply.content).to eq(newcontent)
        end
      end
      
      describe "and sends with wrong information" do
        before do
          fill_in "Réponse", with: ""
          click_button "Modifier"
          savedreply.reload
        end
        specify do
          expect(page).to have_error_message("Réponse doit être rempli")
          expect(page).to have_selector("h1", text: "Modifier une réponse")
          expect(savedreply.content).to_not eq("")
        end
      end
    end
    
    describe "edits a generic saved reply" do
      before { visit edit_savedreply_path(savedreply_generic, :sub => submission) }
      it { should have_selector("h1", text: "Modifier une réponse") }
      
      describe "and makes it specific to the problem" do
        before do
          select "Problème ##{problem.number}", from: "Problème"
          fill_in "Réponse", with: newcontent
          click_button "Modifier"
          savedreply_generic.reload
        end
        specify do
          expect(page).to have_success_message("Réponse modifiée")
          expect(page).to have_selector("h1", text: "Problème ##{problem.number}")
          expect(page).to have_content(submission.content)
          expect(page).to have_link("2 réponses spécifiques")
          expect(savedreply_generic.problem).to eq(problem)
          expect(savedreply_generic.content).to eq(newcontent)
        end
      end
    end
  end
end
