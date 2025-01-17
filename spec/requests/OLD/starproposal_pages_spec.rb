# -*- coding: utf-8 -*-
require "spec_helper"

describe "Star proposal pages" do

  subject { page }

  let(:root) { FactoryGirl.create(:root) }
  let(:corrector) { FactoryGirl.create(:corrector) }
  
  let!(:problem) { FactoryGirl.create(:problem, online: true, level: 1) }
  let!(:correct_submission) { FactoryGirl.create(:submission, problem: problem, status: :correct) }
  let!(:correct_submission2) { FactoryGirl.create(:submission, problem: problem, status: :correct) }
  let!(:wrong_submission) { FactoryGirl.create(:submission, problem: problem, status: :wrong) }
  
  let!(:corrector_submission) { FactoryGirl.create(:submission, problem: problem, status: :correct) }
  let!(:corrector_solvedproblem) { FactoryGirl.create(:solvedproblem, problem: problem, submission: corrector_submission, user: corrector) }
  
  let(:new_reason) { "Très belle solution." }
  let(:new_answer) { "Voici ma réponse." }
  
  describe "corrector" do
    before { sign_in corrector }
    
    describe "visits wrong submission" do
      before { visit problem_path(problem, :sub => wrong_submission) }
      it do
        should have_selector("h1", text: "Problème ##{problem.number}")
        should have_selector("div", text: wrong_submission.content)
        should have_no_link("Proposer une étoile")
      end
    end
    
    describe "visits correct submission" do
      before { visit problem_path(problem, :sub => correct_submission) }
      it do
        should have_selector("h1", text: "Problème ##{problem.number}")
        should have_selector("div", text: correct_submission.content)
        should have_link("Proposer une étoile")
        should have_button("Envoyer pour traitement") # in test environment it is always shown
      end
      
      describe "and submits a new proposal" do
        before do
          fill_in "new_reason_field", with: new_reason
          click_button "new_starproposal_button"
        end
        specify do
          expect(page).to have_success_message("Proposition d'étoile envoyée.")
          expect(page).to have_selector("td", text: new_reason)
          expect(page).to have_selector("td", text: "En attente")
          expect(page).to have_no_link("Traîter")
          expect(page).to have_no_button("Modifier")
          expect(page).to have_no_link("Supprimer")
          expect(correct_submission.starproposals.order(:id).last.reason).to eq(new_reason)
          expect(correct_submission.starproposals.order(:id).last.user).to eq(corrector)
          expect(correct_submission.starproposals.order(:id).last.waiting_treatment?).to eq(true)
        end
      end
      
      describe "and submits an empty proposal" do
        before do
          fill_in "new_reason_field", with: ""
          click_button "new_starproposal_button"
        end
        it { should have_error_message("Raison doit être rempli") }
      end
      
      describe "and submits a proposal while the submission has been marked incorrect" do
        before do
          correct_submission.wrong!
          fill_in "new_reason_field", with: new_reason
          click_button "new_starproposal_button"
        end
        specify do
          expect(page).to have_error_message("La soumission n'est pas correcte.")
          expect(correct_submission.starproposals.count).to eq(0)
        end
      end
    end
    
    describe "visits his proposals" do
      let!(:starproposal1) { FactoryGirl.create(:starproposal, :user => corrector, :status => :waiting_treatment) }
      let!(:starproposal2) { FactoryGirl.create(:starproposal, :user => corrector, :status => :rejected) }
      let!(:starproposal_root) { FactoryGirl.create(:starproposal, :user => root, :status => :accepted) }
      before { visit starproposals_path }
      it do
        should have_selector("h1", text: "Propositions d'étoiles")
        should have_no_link("Tout voir")
        should have_no_link("Voir nouvelles propositions")
        should have_link("Voir", href: problem_path(starproposal1.submission.problem, :sub => starproposal1.submission))
        should have_link("Voir", href: problem_path(starproposal2.submission.problem, :sub => starproposal2.submission))
        should have_no_link("Voir", href: problem_path(starproposal_root.submission.problem, :sub => starproposal_root.submission))
      end
    end
  end
  
  describe "root" do
    before { sign_in root }
    
    describe "visits waiting star proposals" do
      let!(:starproposal1) { FactoryGirl.create(:starproposal, :user => corrector, :submission => correct_submission, :status => :waiting_treatment) }
      let!(:starproposal2) { FactoryGirl.create(:starproposal, :user => corrector, :submission => correct_submission2, :status => :accepted) }
      before { visit starproposals_path }
      it do
        should have_selector("h1", text: "Propositions d'étoiles")
        should have_link("Tout voir")
        should have_no_link("Voir nouvelles propositions")
        should have_link("Voir", href: problem_path(starproposal1.submission.problem, :sub => starproposal1.submission))
        should have_no_link("Voir", href: problem_path(starproposal2.submission.problem, :sub => starproposal2.submission))
      end
      
      describe "and then visits all proposals" do
        before { click_link "Tout voir" }
        it do
          should have_selector("h1", text: "Propositions d'étoiles")
          should have_no_link("Tout voir")
          should have_link("Nouvelles propositions uniquement")
          should have_link("Voir", href: problem_path(starproposal1.submission.problem, :sub => starproposal1.submission))
          should have_link("Voir", href: problem_path(starproposal2.submission.problem, :sub => starproposal2.submission))
        end
      end
    end
    
    describe "visits a submission with waiting star proposal" do
      let!(:starproposal) { FactoryGirl.create(:starproposal, :user => corrector, :submission => correct_submission, :status => :waiting_treatment) }
      before { visit problem_path(problem, :sub => correct_submission) }
      specify do
        expect(page).to have_selector("td", text: starproposal.reason)
        expect(page).to have_selector("td", text: "En attente")
        expect(page).to have_link("Traîter")
        expect(page).to have_link("Supprimer", href: starproposal_path(starproposal)) # in test environment it is always shown
        expect(page).to have_button("Modifier") # in test environment it is always shown
        expect(page).to have_link("Proposer une étoile")
        expect(page).to have_button("Envoyer pour traitement") # in test environment it is always shown
        expect { click_link("Supprimer") }.to change{correct_submission.starproposals.count}.by(-1)
      end
      
      describe "and mark it as accepted" do
        before do
          fill_in "edit_answer_field_#{starproposal.id}", with: new_answer
          select "Accepté", from: "edit_status_field_#{starproposal.id}"
          click_button "edit_button_#{starproposal.id}"
          starproposal.reload
          correct_submission.reload
        end
        specify do
          expect(starproposal.answer).to eq(new_answer)
          expect(starproposal.accepted?).to eq(true)
          expect(correct_submission.star?).to eq(true)
        end
      end
    end
  end
end
