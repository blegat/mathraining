# -*- coding: utf-8 -*-
require "spec_helper"

describe "Savedreply pages", savedreply: true do

  subject { page }

  let(:admin) { FactoryBot.create(:admin) }
  let(:root) { FactoryBot.create(:root) }
  let!(:section) { FactoryBot.create(:section, short_abbreviation: "A. B.") }
  let!(:problem) { FactoryBot.create(:problem, section: section, online: true) }
  let!(:submission) { FactoryBot.create(:submission, problem: problem, status: :waiting) }
  let!(:savedreply_generic) { FactoryBot.create(:savedreply, content: "Es-tu sûr[e] de toi ?") }
  let!(:savedreply_section) { FactoryBot.create(:savedreply, section: problem.section) }
  let!(:savedreply_problem) { FactoryBot.create(:savedreply, problem: problem) }
  let(:newcontent) { "Es-tu certain que $1$ est un nombre premier ?" }

  describe "root" do
    before { sign_in root }
    
    describe "visits submission" do
      before { visit problem_path(problem, :sub => submission) }
      specify do
        expect(page).to have_link("1 rép. gén.")
        expect(page).to have_link("1 rép. A. B.")
        expect(page).to have_link("1 rép. ##{problem.number}")
        expect(page).to have_link("+", href: new_savedreply_path(:sub => submission))
      end
      
      describe "and deletes a saved reply", :js => true do
        before do
          click_link "1 rép. gén."
        end
        specify { expect { click_link("Supprimer", href: savedreply_path(savedreply_generic)) }.to change(Savedreply, :count).by(-1) }
      end
      
      describe "and uses a saved reply", :js => true do
        before do
          click_button "Réserver cette soumission"
          wait_for_ajax
          click_link "1 rép. gén."
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
          expect(problem.savedreplies.order(:id).last.approved).to eq(true)
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
          expect(page).to have_link("2 rép. gén.")
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
    
    describe "visits path associated to generic saved reply" do
      before { visit savedreply_path(savedreply_generic) }
      it { should have_current_path(problem_path(problem, :sub => submission)) }
    end
    
    describe "visits path associated to section saved reply" do
      before { visit savedreply_path(savedreply_section) }
      it { should have_current_path(problem_path(problem, :sub => submission)) }
    end
    
    describe "visits path associated to problem saved reply" do
      before { visit savedreply_path(savedreply_problem) }
      it { should have_current_path(problem_path(problem, :sub => submission)) }
    end
  end
  
  describe "admin" do
    before { sign_in admin }
    
    describe "creates a saved reply" do
      before do
        visit new_savedreply_path(:sub => submission)
        select section.name, from: "Problème"
        fill_in "Réponse", with: newcontent
        click_button "Créer"
      end
      specify do
        expect(page).to have_success_message("Réponse ajoutée")
        expect(page).to have_selector("h1", text: "Problème ##{problem.number}")
        expect(page).to have_content(submission.content)
        expect(section.savedreplies.order(:id).last.content).to eq("(Proposé par #{admin.name})\n\n" + newcontent)
        expect(section.savedreplies.order(:id).last.problem_id).to eq(0)
        expect(section.savedreplies.order(:id).last.user_id).to eq(0)
        expect(section.savedreplies.order(:id).last.approved).to eq(false)
      end
      
      describe "and root approves it" do
        let(:savedreply) { section.savedreplies.order(:id).last }
        before do
          sign_out
          sign_in root
          visit edit_savedreply_path(savedreply, :sub => submission)
          click_button "Modifier"
          savedreply.reload
        end
        specify do
          expect(page).to have_success_message("Réponse modifiée")
          expect(page).to have_selector("h1", text: "Problème ##{problem.number}")
          expect(page).to have_content(submission.content)
          expect(savedreply.content).to eq(newcontent) # (Proposé par...) has been removed in edit
          expect(savedreply.approved).to eq(true)
        end
      end
    end
    
    describe "creates a personal saved reply" do
      before do
        visit new_savedreply_path(:sub => submission)
        select "Générique (personnelle)", from: "Problème"
        fill_in "Réponse", with: newcontent
        click_button "Créer"
      end
      specify do
        expect(page).to have_success_message("Réponse ajoutée")
        expect(page).to have_selector("h1", text: "Problème ##{problem.number}")
        expect(page).to have_content(submission.content)
        expect(admin.savedreplies.order(:id).last.content).to eq(newcontent) # No "(Proposé par...) for a personal savedreply
        expect(admin.savedreplies.order(:id).last.problem_id).to eq(0)
        expect(admin.savedreplies.order(:id).last.section_id).to eq(0)
        expect(admin.savedreplies.order(:id).last.approved).to eq(true)
      end
      
      describe "and updates it to be non-personal" do
        let(:savedreply) { admin.savedreplies.order(:id).last }
        before do
          visit edit_savedreply_path(savedreply, :sub => submission)
          select "Générique", from: "Problème"
          click_button "Modifier"
          savedreply.reload
        end
        specify do
          expect(page).to have_success_message("Réponse modifiée")
          expect(page).to have_selector("h1", text: "Problème ##{problem.number}")
          expect(page).to have_content(submission.content)
          expect(savedreply.content).to eq("(Proposé par #{admin.name})\n\n" + newcontent)
          expect(savedreply.user_id).to eq(0)
          expect(savedreply.approved).to eq(false)
        end
      end
    end
  end
end
