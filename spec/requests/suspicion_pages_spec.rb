# -*- coding: utf-8 -*-
require "spec_helper"

describe "Suspicion pages", suspicion: true do

  subject { page }

  let(:root) { FactoryBot.create(:root) }
  let(:corrector) { FactoryBot.create(:corrector) }
  
  let!(:problem) { FactoryBot.create(:problem, online: true, level: 1) }
  let!(:waiting_submission) { FactoryBot.create(:submission, problem: problem, status: :waiting) }
  let!(:correct_submission) { FactoryBot.create(:submission, problem: problem, status: :correct) }
  let!(:wrong_submission) { FactoryBot.create(:submission, problem: problem, status: :wrong) }
  
  let!(:plagiarized_submission) { FactoryBot.create(:submission, problem: problem, status: :plagiarized) }
  
  let!(:corrector_submission) { FactoryBot.create(:submission, problem: problem, status: :correct) }
  let!(:corrector_solvedproblem) { FactoryBot.create(:solvedproblem, problem: problem, submission: corrector_submission, user: corrector) }
  
  let(:new_source) { "http://www.pleindesolutions.com" }
  
  describe "corrector" do
    before { sign_in corrector }
    
    describe "visits wrong submission" do
      before { visit problem_submission_path(problem, wrong_submission) }
      it do
        should have_selector("h1", text: "Problème ##{problem.number}")
        should have_selector("div", text: wrong_submission.content)
        should have_link("Soumettre une nouvelle suspicion de plagiat")
        should have_button("Envoyer pour confirmation") # in test environment it is always shown
      end
        
      describe "and submits a new suspicion" do
        before do
          fill_in "suspicion_source", with: new_source
          click_button "new_suspicion_button"
        end
        specify do
          expect(page).to have_success_message("Suspicion envoyée pour confirmation.")
          expect(page).to have_selector("td", text: new_source)
          expect(page).to have_selector("td", text: "À confirmer")
          expect(page).to have_no_link("Modifier")
          expect(page).to have_no_button("Modifier")
          expect(page).to have_no_link("Supprimer")
          expect(wrong_submission.suspicions.order(:id).last.source).to eq(new_source)
          expect(wrong_submission.suspicions.order(:id).last.user).to eq(corrector)
          expect(wrong_submission.suspicions.order(:id).last.waiting_confirmation?).to eq(true)
        end
      end
      
      describe "and submits an empty suspicion" do
        before do
          fill_in "suspicion_source", with: ""
          click_button "new_suspicion_button"
        end
        it { should have_error_message("Source doit être rempli") }
      end
    end
    
    describe "visits his suspicions" do
      let!(:suspicion1) { FactoryBot.create(:suspicion, :user => corrector, :status => :waiting_confirmation) }
      let!(:suspicion2) { FactoryBot.create(:suspicion, :user => corrector, :status => :rejected) }
      let!(:suspicion_root) { FactoryBot.create(:suspicion, :user => root, :status => :forgiven) }
      before { visit suspicions_path }
      it do
        should have_selector("h1", text: "Suspicions de plagiat")
        should have_no_link("Tout voir")
        should have_no_link("Voir nouvelles suspicions")
        should have_link("Voir", href: problem_submission_path(suspicion1.submission.problem, suspicion1.submission))
        should have_link("Voir", href: problem_submission_path(suspicion2.submission.problem, suspicion2.submission))
        should have_no_link("Voir", href: problem_submission_path(suspicion_root.submission.problem, suspicion_root.submission))
      end
    end
  end
  
  describe "root" do
    before { sign_in root }
    
    describe "visits waiting suspicions" do
      let!(:suspicion1) { FactoryBot.create(:suspicion, :user => corrector, :submission => wrong_submission, :status => :waiting_confirmation) }
      let!(:suspicion2) { FactoryBot.create(:suspicion, :user => corrector, :submission => correct_submission, :status => :waiting_confirmation) }
      let!(:suspicion3) { FactoryBot.create(:suspicion, :user => corrector, :submission => plagiarized_submission, :status => :confirmed) }
      before { visit suspicions_path }
      it do
        should have_selector("h1", text: "Suspicions de plagiat")
        should have_link("Tout voir")
        should have_no_link("Voir nouvelles suspicions")
        should have_link("Voir", href: problem_submission_path(suspicion1.submission.problem, suspicion1.submission))
        should have_link("Voir", href: problem_submission_path(suspicion2.submission.problem, suspicion2.submission))
        should have_no_link("Voir", href: problem_submission_path(suspicion3.submission.problem, suspicion3.submission))
      end
      
      describe "and then visits all suspicions" do
        before { click_link "Tout voir" }
        it do
          should have_selector("h1", text: "Suspicions de plagiat")
          should have_no_link("Tout voir")
          should have_link("Nouvelles suspicions uniquement")
          should have_link("Voir", href: problem_submission_path(suspicion1.submission.problem, suspicion1.submission))
          should have_link("Voir", href: problem_submission_path(suspicion2.submission.problem, suspicion2.submission))
          should have_link("Voir", href: problem_submission_path(suspicion3.submission.problem, suspicion3.submission))
        end
      end
    end
    
    describe "visits a submission with waiting suspicion" do
      let!(:suspicion) { FactoryBot.create(:suspicion, :user => corrector, :submission => wrong_submission, :status => :waiting_confirmation) }
      before { visit problem_submission_path(problem, wrong_submission) }
      specify do
        expect(page).to have_selector("td", text: suspicion.source)
        expect(page).to have_selector("td", text: "À confirmer")
        expect(page).to have_link("Modifier")
        expect(page).to have_link("Supprimer", href: suspicion_path(suspicion)) # in test environment it is always shown
        expect(page).to have_button("Modifier") # in test environment it is always shown
        expect(page).to have_link("Soumettre une nouvelle suspicion de plagiat")
        expect(page).to have_button("Envoyer pour confirmation") # in test environment it is always shown
        expect { click_link("Supprimer") }.to change{wrong_submission.suspicions.count}.by(-1)
      end
      
      describe "and mark it as confirmed" do
        before do
          select root.name, from: "edit_user_field_#{suspicion.id}"
          fill_in "edit_source_field_#{suspicion.id}", with: new_source
          select "Confirmé", from: "edit_status_field_#{suspicion.id}"
          click_button "edit_button_#{suspicion.id}"
          suspicion.reload
          wrong_submission.reload
        end
        specify do
          expect(suspicion.user).to eq(root)
          expect(suspicion.source).to eq(new_source)
          expect(suspicion.confirmed?).to eq(true)
          expect(wrong_submission.plagiarized?).to eq(true)
          expect(page).to have_link("Sanctionner #{wrong_submission.user.name}")
        end
      end
    end
    
    describe "visits a reserved waiting submission in test with suspicion" do
      let!(:suspicion) { FactoryBot.create(:suspicion, :user => corrector, :submission => waiting_submission, :status => :waiting_confirmation) }
      let!(:reservation) { FactoryBot.create(:following, :user => corrector, :submission => waiting_submission, :kind => :reservation) }
      before do
        waiting_submission.update(:intest => true, :score => -1)
        visit problem_submission_path(problem, waiting_submission)
      end
      it do
        should have_selector("div", text: "Cette soumission est en train d'être corrigée par #{corrector.name}")
        should have_selector("td", text: suspicion.source)
        should have_selector("td", text: "À confirmer")
        should have_link("Modifier")
      end
      
      describe "and confirms the suspicion" do
        before do
          select "Confirmé", from: "edit_status_field_#{suspicion.id}"
          click_button "edit_button_#{suspicion.id}"
          suspicion.reload
          waiting_submission.reload
        end
        specify do
          expect(suspicion.confirmed?).to eq(true)
          expect(waiting_submission.plagiarized?).to eq(true)
          expect(waiting_submission.score).to eq(0)
          expect(corrector.followings.where(:submission => waiting_submission, :kind => :reservation).count).to eq(0) # reservation should be deleted
          expect(corrector.followings.where(:submission => waiting_submission, :kind => :first_corrector).count).to eq(1) # corrector "corrected" that submission
        end
      end
      
      describe "and forgives the suspicion" do
        before do
          select "Pardonné", from: "edit_status_field_#{suspicion.id}"
          click_button "edit_button_#{suspicion.id}"
          waiting_submission.reload
        end
        specify do
          expect(page).to have_selector("td", text: "Pardonné")
          expect(waiting_submission.plagiarized?).to eq(false)
          expect(waiting_submission.score).to eq(-1)
          expect(corrector.followings.where(:submission => waiting_submission, :kind => :reservation).count).to eq(1) # reservation should not be deleted
          expect(corrector.followings.where(:submission => waiting_submission, :kind => :first_corrector).count).to eq(0) # should not be created
        end
      end
    end
    
    describe "confirms suspicion on a correct submission" do
      let!(:suspicion) { FactoryBot.create(:suspicion, :user => corrector, :submission => correct_submission, :status => :rejected) }
      let!(:correction) { FactoryBot.create(:correction, :user => corrector, :submission => correct_submission) }
      let!(:solvedproblem) { FactoryBot.create(:solvedproblem, :user => correct_submission.user, :problem => problem, :submission => correct_submission) }
      before do
        correct_submission.user.update_attribute(:rating, 200)
        visit problem_submission_path(problem, correct_submission)
        select "Confirmé", from: "edit_status_field_#{suspicion.id}"
        click_button "edit_button_#{suspicion.id}"
        suspicion.reload
        correct_submission.reload
        correct_submission.user.reload
      end
      specify do
        expect(suspicion.confirmed?).to eq(true)
        expect(correct_submission.plagiarized?).to eq(true)
        expect(correct_submission.user.rating).to eq(200 - 15)
        expect(correct_submission.user.pb_solved?(problem)).to eq(false)
      end
    end
    
    describe "unconfirms a suspicion on a plagiarized submission without comment" do
      let!(:suspicion) { FactoryBot.create(:suspicion, :user => corrector, :submission => plagiarized_submission, :status => :confirmed) }
      let!(:auto_following) { FactoryBot.create(:following, :user => corrector, :submission => plagiarized_submission, :kind => :first_corrector) }
      before do
        visit problem_submission_path(problem, plagiarized_submission)
        select "Rejeté", from: "edit_status_field_#{suspicion.id}"
        click_button "edit_button_#{suspicion.id}"
        suspicion.reload
        plagiarized_submission.reload
      end
      specify do
        expect(suspicion.rejected?).to eq(true)
        expect(plagiarized_submission.waiting?).to eq(true) # waiting because there is no comment on this submission
        expect(plagiarized_submission.followings.count).to eq (0) # auto_following should be deleted automatically
      end
    end
    
    describe "unconfirms a suspicion on a plagiarized submission with a comment" do
      let!(:suspicion) { FactoryBot.create(:suspicion, :user => corrector, :submission => plagiarized_submission, :status => :confirmed) }
      let!(:correction) { FactoryBot.create(:correction, :user => root, :submission => plagiarized_submission) }
      before do
        visit problem_submission_path(problem, plagiarized_submission)
        select "Pardonné", from: "edit_status_field_#{suspicion.id}"
        click_button "edit_button_#{suspicion.id}"
        suspicion.reload
        plagiarized_submission.reload
      end
      specify do
        expect(suspicion.forgiven?).to eq(true)
        expect(plagiarized_submission.wrong?).to eq(true) # wrong because there is a comment on this submission
      end
    end
  end
end
