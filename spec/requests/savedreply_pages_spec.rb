# -*- coding: utf-8 -*-
require "spec_helper"

describe "Savedreply pages", savedreply: true do

  subject { page }

  let(:root) { FactoryGirl.create(:root) }
  let!(:section) { FactoryGirl.create(:section, short_abbreviation: "A. B.") }
  let!(:problem) { FactoryGirl.create(:problem, section: section, online: true) }
  let!(:submission) { FactoryGirl.create(:submission, problem: problem, status: :waiting) }
  let!(:savedreply_generic) { FactoryGirl.create(:savedreply, content: "Es-tu sûr[e] de toi ?") }
  let!(:savedreply_section) { FactoryGirl.create(:savedreply, section: problem.section) }
  let!(:savedreply_problem) { FactoryGirl.create(:savedreply, problem: problem) }
  let(:newcontent) { "Es-tu certain que $1$ est un nombre premier ?" }

  describe "root" do
    before { sign_in root }
    
    describe "visits submission" do
      before { visit problem_path(problem, :sub => submission) }
      specify do
        expect(page).to have_link("1 rép. générique")
        expect(page).to have_link("1 rép. A. B.")
        expect(page).to have_link("1 rép. ##{problem.number}")
        expect(page).to have_link("+", href: new_savedreply_path(:sub => submission))
      end
      
      describe "and deletes a saved reply", :js => true do
        before do
          click_link "1 rép. générique"
        end
        specify { expect { click_link("Supprimer", href: savedreply_path(savedreply_generic)) }.to change(Savedreply, :count).by(-1) }
      end
      
      describe "and uses a saved reply", :js => true do
        before do
          click_button "Réserver cette soumission"
          click_link "1 rép. générique"
          find("#savedreply-#{savedreply_generic.id}").click() # This registers in a hidden field that the saved reply has been used
          click_button "Poster et refuser la soumission"
          savedreply_generic.reload
          savedreply_section.reload
          savedreply_problem.reload
        end
        specify do
          expect(page).to have_success_message("Soumission marquée comme incorrecte")
          expect(submission.corrections.first.content).to eq("Es-tu sûr de toi ?")
          expect(savedreply_generic.nb_uses).to eq(1)
          expect(savedreply_section.nb_uses).to eq(0)
          expect(savedreply_problem.nb_uses).to eq(0)
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
          expect(page).to have_link("2 rép. ##{problem.number}")
          expect(problem.savedreplies.order(:id).last.content).to eq(newcontent)
          expect(problem.savedreplies.order(:id).last.section_id).to eq(0)
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
    
    describe "edits a saved reply specific to a problem" do
      before { visit edit_savedreply_path(savedreply_problem, :sub => submission) }
      it { should have_selector("h1", text: "Modifier une réponse") }
      
      describe "and makes it generic" do
        before do
          select "Générique", from: "Problème"
          fill_in "Réponse", with: newcontent
          click_button "Modifier"
          savedreply_problem.reload
        end
        specify do
          expect(page).to have_success_message("Réponse modifiée")
          expect(page).to have_selector("h1", text: "Problème ##{problem.number}")
          expect(page).to have_content(submission.content)
          expect(page).to have_link("2 rép. génériques")
          expect(savedreply_problem.problem_id).to eq(0)
          expect(savedreply_problem.section_id).to eq(0)
          expect(savedreply_problem.content).to eq(newcontent)
        end
      end
      
      describe "and sends with wrong information" do
        before do
          fill_in "Réponse", with: ""
          click_button "Modifier"
          savedreply_problem.reload
        end
        specify do
          expect(page).to have_error_message("Réponse doit être rempli")
          expect(page).to have_selector("h1", text: "Modifier une réponse")
          expect(savedreply_problem.content).to_not eq("")
        end
      end
    end
    
    describe "edits a generic saved reply" do
      before { visit edit_savedreply_path(savedreply_generic, :sub => submission) }
      it { should have_selector("h1", text: "Modifier une réponse") }
      
      describe "and makes it specific to the section" do
        before do
          select section.name, from: "Problème"
          fill_in "Réponse", with: newcontent
          click_button "Modifier"
          savedreply_generic.reload
        end
        specify do
          expect(page).to have_success_message("Réponse modifiée")
          expect(page).to have_selector("h1", text: "Problème ##{problem.number}")
          expect(page).to have_content(submission.content)
          expect(page).to have_link("2 rép. A. B.")
          expect(savedreply_generic.problem_id).to eq(0)
          expect(savedreply_generic.section_id).to eq(section.id)
          expect(savedreply_generic.content).to eq(newcontent)
        end
      end
    end
  end
end
