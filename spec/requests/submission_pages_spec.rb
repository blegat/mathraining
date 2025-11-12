# -*- coding: utf-8 -*-
require "spec_helper"

describe "Submission pages", submission: true do

  subject { page }

  let(:root) { FactoryBot.create(:root) }
  let(:admin) { FactoryBot.create(:admin) }
  let(:user) { FactoryBot.create(:advanced_user) }
  let(:other_user) { FactoryBot.create(:advanced_user) }
  let(:other_user2) { FactoryBot.create(:advanced_user) }
  let(:good_corrector) { FactoryBot.create(:corrector) }
  let(:bad_corrector) { FactoryBot.create(:corrector) }
  
  let!(:section) { FactoryBot.create(:section) }
  
  let!(:problem) { FactoryBot.create(:problem, online: true, section: section, level: 1) }
  let!(:problem_with_submissions) { FactoryBot.create(:problem, online: true, section: section, level: 1) }
  
  let!(:waiting_submission) { FactoryBot.create(:submission, problem: problem_with_submissions, user: user, status: :waiting) } 
  let!(:wrong_submission) { FactoryBot.create(:submission, problem: problem_with_submissions, user: other_user, status: :wrong) }
  let!(:good_submission) { FactoryBot.create(:submission, problem: problem_with_submissions, user: other_user2, status: :correct, created_at: DateTime.now - 2.days) }
  let!(:good_solvedproblem) { FactoryBot.create(:solvedproblem, problem: problem_with_submissions, submission: good_submission, resolution_time: good_submission.created_at, user: other_user2) }
  
  let!(:good_corrector_submission) { FactoryBot.create(:submission, problem: problem_with_submissions, user: good_corrector, status: :correct, created_at: DateTime.now - 1.day) }
  let!(:good_corrector_solvedproblem) { FactoryBot.create(:solvedproblem, problem: problem_with_submissions, submission: good_corrector_submission, resolution_time: good_corrector_submission.created_at, user: good_corrector) }
  
  let(:newsubmission) { "Voici ma belle soumission." }
  let(:newcorrection) { "Voici ma belle correction." }
  let(:newanswer) { "Voici ma réponse." }
  let(:newsubmission2) { "Voici ma nouvelle soumission." }
  let(:newcorrection2) { "Voici ma nouvelle correction." }
  
  let(:attachments_folder) { "./spec/attachments/" }
  let(:image1) { "mathraining.png" } # default image used in factory
  let(:image2) { "Smiley1.gif" }
  let(:exe_attachment) { "hack.exe" }
  
  describe "user" do
    before { sign_in user }

    describe "visits problem" do
      before { visit problem_path(problem) }
      it do
        should have_selector("h1", text: "Problème ##{problem.number}")
        should have_selector("div", text: problem.statement)
        should have_link("Nouvelle soumission")
      end
    end
      
    describe "visits new submission page" do
      before { visit new_problem_submission_path(problem) }
      it do
        should have_selector("h3", text: "Énoncé")
        should have_selector("h3", text: "Nouvelle soumission")
        should have_button("Enregistrer cette solution")
        should have_no_button("Annuler") # Only shown inside a test
      end
      
      describe "and sends new empty submission" do
        before do
          fill_in "MathInput", with: ""
          click_button "Enregistrer cette solution"
        end
        it { should have_error_message("Solution doit être rempli") }
      end
      
      describe "and sends new submission" do
        before do
          fill_in "MathInput", with: newsubmission
          click_button "Enregistrer cette solution"
          click_button "Soumettre cette solution"
        end
        specify do
          expect(page).to have_success_message("Votre solution a bien été soumise pour être corrigée.")
          expect(page).to have_selector("h3", text: "Soumission (en attente de correction)")
          expect(page).to have_selector("div", text: newsubmission)
          expect(problem.submissions.order(:id).last.content).to eq(newsubmission)
          expect(problem.submissions.order(:id).last.waiting?).to eq(true)
        end
      end
      
      describe "and writes new draft with expired session (or invalid CSRF token)" do
        before do
          ActionController::Base.allow_forgery_protection = true # Don't know why but this is enough to have an invalid CSRF in testing
          #Capybara.current_session.driver.browser.set_cookie("_session_id=wrongValue")
          fill_in "MathInput", with: newsubmission
          click_button "Enregistrer cette solution"
        end
        it do
          should have_error_message("Votre session a expiré")
          should have_selector("textarea", text: newsubmission) # The submission should not be lost!
        end
        after { ActionController::Base.allow_forgery_protection = false }
      end
      
      describe "and writes new draft while submissions are forbidden" do
        before do
          Globalvariable.create(:key => "no_new_submission", :value => 1, :message => "On ne soumet plus pour l'instant !")
          fill_in "MathInput", with: newsubmission
          click_button "Enregistrer cette solution"
        end
        specify { expect(problem.submissions.count).to eq(0) }
      end
      
      describe "and writes new draft while a submission is already waiting" do # Can only be done with several tabs
        before do
          FactoryBot.create(:submission, problem: problem, user: user, status: :waiting)
          fill_in "MathInput", with: newsubmission
          click_button "Enregistrer cette solution"
        end
        specify do
          expect(page).to have_selector("h1", text: "Problème ##{problem.number}")
          expect(page).to have_no_link("Nouvelle soumission")
          expect(problem.submissions.order(:id).last.content).not_to eq(newsubmission)
          expect(problem.submissions.where(:user => user).count).to eq(1) # Only the one created by FactoryBot 
        end
      end
    end
      
    describe "visits problem with a draft" do
      let!(:draft_submission) { FactoryBot.create(:submission, problem: problem, user: user, status: :draft, content: newsubmission) }
      before { visit problem_path(problem) }
      it do
        should have_selector("h1", text: "Problème ##{problem.number}")
        should have_selector("div", text: problem.statement)
        should have_link("Reprendre le brouillon")
      end
    end
    
    describe "visits draft page" do
      let!(:draft_submission) { FactoryBot.create(:submission, problem: problem, user: user, status: :draft, content: newsubmission) }
      before { visit new_problem_submission_path(problem) }
      it do
        should have_selector("h3", text: "Énoncé")
        should have_selector("h3", text: "Nouvelle soumission")
        should have_link("Modifier la solution")
        should have_link("Supprimer la solution")
        should have_button("Soumettre cette solution")
      end
        
      specify { expect { click_link "Supprimer la solution" }.to change(Submission, :count).by(-1) }
        
      describe "and updates the draft" do
        before do
          fill_in "MathInput", with: newsubmission2
          click_button "Enregistrer cette solution"
          draft_submission.reload
        end
        specify do
          expect(page).to have_success_message("Votre solution a bien été enregistrée.")
          expect(page).to have_selector("h3", text: "Nouvelle soumission")
          expect(draft_submission.content).to eq(newsubmission2)
        end
      end
      
      describe "and updates the draft for an empty draft" do
        before do
          fill_in "MathInput", with: ""
          click_button "Enregistrer cette solution"
          draft_submission.reload
        end
        specify do
          expect(page).to have_error_message("Solution doit être rempli")
          expect(draft_submission.content).to eq(newsubmission)
        end
      end
      
      describe "and sends the draft as submission" do
        before do
          click_button "Soumettre cette solution"
          draft_submission.reload
        end
        specify do
          expect(page).to have_success_message("Votre solution a bien été soumise pour être corrigée.")
          expect(page).to have_selector("h3", text: "Soumission (en attente de correction)")
          expect(page).to have_selector("div", text: newsubmission)
          expect(draft_submission.content).to eq(newsubmission)
          expect(draft_submission.waiting?).to eq(true)
        end
      end
      
      describe "and tries to send the draft while another submission was sent the same day" do
        before do
          Globalvariable.create(key: :limited_new_submissions, value: 1)
          click_button "Soumettre cette solution"
          draft_submission.reload
        end
        specify do
          expect(page).not_to have_success_message("Votre solution a bien été soumise pour être corrigée.")
          expect(page).to have_selector("h3", text: "Nouvelle soumission")
          expect(page).to have_content("Vous avez déjà soumis")
          expect(draft_submission.draft?).to eq(true)
        end
      end
      
      describe "and tries to update a draft that is already sent" do # Can only be done with several tabs
        before do
          draft_submission.waiting!
          fill_in "MathInput", with: newsubmission2
          click_button "Enregistrer cette solution"
          draft_submission.reload
        end
        specify do
          expect(page).to_not have_success_message("Votre solution a bien été enregistrée.")
          expect(page).to have_selector("h1", text: "Problème ##{problem.number}") # We simply redirect in this case (because it could happen)
          expect(draft_submission.content).to eq(newsubmission)
          expect(draft_submission.waiting?).to eq(true)
        end
      end
    end
    
    describe "sends a submission to a virtualtest problem (later)" do
      let!(:virtualtest) { FactoryBot.create(:virtualtest, online: true) }
      let!(:takentest) { Takentest.create(virtualtest: virtualtest, user: user, status: :finished, taken_time: DateTime.now - 2.days) }
      before do
        problem.update_attribute(:virtualtest, virtualtest)
        visit problem_path(problem)
        click_link("Nouvelle soumission")
        fill_in "MathInput", with: newsubmission
        click_button "Enregistrer cette solution"
        click_button "Soumettre cette solution"
      end
      specify do
        expect(problem.submissions.order(:id).last.content).to eq(newsubmission)
        expect(problem.submissions.order(:id).last.waiting?).to eq(true)
        expect(problem.submissions.order(:id).last.intest?).to eq(false)
        expect(page).to have_selector("h3", text: "Soumission (en attente de correction)")
        expect(page).to have_selector("div", text: newsubmission)
      end
    end
  end
  
  describe "bad corrector" do
    before { sign_in bad_corrector }
    it { should have_link("0", href: allnew_submissions_path(:levels => 3)) } # 0 waiting submission of level 1, 2 (because cannot see it)
    
    describe "visits submissions page" do
      before { visit allnew_submissions_path(:levels => 3) }
      it do
        should have_selector("h1", text: "Soumissions")
        should have_no_link(user.name, href: user_path(user))
      end
    end
     
    describe "visits waiting submission" do
      before { visit problem_submission_path(problem_with_submissions, waiting_submission) }
      it do
        should have_no_selector("h3", text: "Soumission (en attente de correction)")
        should have_no_selector("div", text: waiting_submission.content)
      end
    end
  end
    
  describe "good corrector" do
    before { sign_in good_corrector }
    it { should have_link("1", href: allnew_submissions_path(:levels => 3)) } # 1 waiting submission
    
    describe "visits submissions page" do
      before { visit allnew_submissions_path(:levels => 3) }
      it do
        should have_selector("h1", text: "Soumissions")
        should have_link(user.name, href: user_path(user))
      end
    end
    
    describe "visits problem with waiting submission" do
      before { visit problem_path(problem_with_submissions) }
      it do
        should have_link("Voir", href: problem_submission_path(problem_with_submissions, good_corrector_submission))
        should have_link("Voir", href: problem_submission_path(problem_with_submissions, waiting_submission))
        should have_no_link("Voir", href: problem_submission_path(problem_with_submissions, wrong_submission))
      end
    end
    
    describe "visits waiting submission" do
      before { visit problem_submission_path(problem_with_submissions, waiting_submission) }
      it do
        should have_selector("h3", text: "Soumission (en attente de correction)")
        should have_selector("div", text: waiting_submission.content)
        should have_button("Poster et refuser la soumission", disabled: true) # Because not reserved
        should have_button("Poster et accepter la soumission", disabled: true) # Because not reserved
      end
    end
      
    describe "visits reserved waiting submission" do
      before do
        FactoryBot.create(:following, user: good_corrector, submission: waiting_submission, read: true, kind: :reservation)
        visit problem_submission_path(problem_with_submissions, waiting_submission) # Reload
      end
      it do
        should have_button("Poster et refuser la soumission")
        should have_button("Poster et accepter la soumission")
      end
      
      describe "and accepts it" do
        let!(:rating_before) { user.rating }
        before do
          fill_in "MathInput", with: newcorrection
          click_button "Poster et accepter la soumission"
          waiting_submission.reload
          user.reload
        end
        specify do
          expect(waiting_submission.correct?).to eq(true)
          expect(waiting_submission.corrections.last.content).to eq(newcorrection)
          expect(page).to have_selector("h3", text: "Soumission (correcte)")
          expect(page).to have_selector("div", text: newcorrection)
          expect(page).to have_link("0", href: allnew_submissions_path(:levels => 3)) # no more waiting submission
          expect(page).to have_link("Marquer comme erronée")
          expect(page).to have_no_link("Étoiler cette solution") # only for roots
          expect(user.rating).to eq(rating_before + waiting_submission.problem.value)
        end
        
        describe "and mark as wrong because of a misclick" do
          before do
            click_link "Marquer comme erronée"
            waiting_submission.reload
            user.reload
          end
          specify do
            expect(waiting_submission.wrong?).to eq(true)
            expect(page).to have_selector("h3", text: "Soumission (erronée)")
            expect(page).to have_no_link("Marquer comme erronée")
            expect(user.rating).to eq(rating_before)
          end
        end
        
        describe "and mark as wrong but too late" do
          before do
            waiting_submission.corrections.last.update_attribute(:created_at, DateTime.now - 20.minutes)
            click_link "Marquer comme erronée"
            waiting_submission.reload
            user.reload
          end
          specify do
            expect(waiting_submission.correct?).to eq(true)
            expect(page).to have_error_message("Vous ne pouvez plus marquer cette solution comme erronée")
            expect(page).to have_selector("h3", text: "Soumission (correcte)")
            expect(page).to have_no_link("Marquer comme erronée") # Because too late
            expect(user.rating).to eq(rating_before + problem_with_submissions.value)
          end
        end
      end
      
      describe "and tries to accept it without any comment" do
        before do
          fill_in "MathInput", with: ""
          click_button "Poster et accepter la soumission"
          waiting_submission.reload
        end
        specify do
          expect(page).to have_error_message("Commentaire doit être rempli")
          expect(waiting_submission.waiting?).to eq(true)
          expect(waiting_submission.corrections.count).to eq(0)
        end
      end
      
      describe "and rejects it while another comment was posted" do
        before do
          FactoryBot.create(:correction, submission: waiting_submission, user: user, content: "J'ajoute une précision")
          fill_in "MathInput", with: newcorrection
          click_button "Poster et refuser la soumission"
          waiting_submission.reload
        end
        specify do
          expect(page).to have_error_message("Un nouveau commentaire a été posté avant le vôtre !")
          expect(waiting_submission.waiting?).to eq(true)
          expect(waiting_submission.corrections.count).to eq(1)
        end
      end
      
      describe "and rejects it" do
        let!(:rating_before) { user.rating }
        before do
          fill_in "MathInput", with: newcorrection
          click_button "Poster et refuser la soumission"
          waiting_submission.reload
        end
        specify do
          expect(waiting_submission.wrong?).to eq(true)
          expect(waiting_submission.corrections.last.content).to eq(newcorrection)
          expect(waiting_submission.notified_users.exists?(user.id)).to eq(true)
          expect(page).to have_selector("h3", text: "Soumission (erronée)")
          expect(page).to have_selector("div", text: newcorrection)
          expect(page).to have_link("0", href: allnew_submissions_path(:levels => 3)) # no more waiting submission
          expect(page).to have_link("Marquer comme correcte")
        end
        
        describe "and mark as correct because of a misclick" do
          before do
            click_link "Marquer comme correcte"
            waiting_submission.reload
            user.reload
          end
          specify do
            expect(waiting_submission.correct?).to eq(true)
            expect(page).to have_selector("h3", text: "Soumission (correcte)")
            expect(page).to have_no_link("Marquer comme correcte")
            expect(page).to have_link("Marquer comme erronée")
            expect(user.rating).to eq(rating_before + problem_with_submissions.value)
          end
        end
        
        describe "and mark as correct but too late" do
          before do
            waiting_submission.corrections.last.update_attribute(:created_at, DateTime.now - 20.minutes)
            click_link "Marquer comme correcte"
            waiting_submission.reload
            user.reload
          end
          specify do
            expect(waiting_submission.wrong?).to eq(true)
            expect(page).to have_error_message("Vous ne pouvez plus marquer cette solution comme correcte sans laisser un commentaire")
            expect(page).to have_selector("h3", text: "Soumission (erronée)")
            expect(page).to have_no_link("Marquer comme correcte") # Because too late
            expect(user.rating).to eq(rating_before)
          end
        end
        
        describe "and admin accepts it" do
          before do
            sign_out
            sign_in admin
            visit problem_submission_path(problem_with_submissions, waiting_submission)
            fill_in "MathInput", with: newcorrection2
            click_button "Poster et accepter la soumission"
            waiting_submission.reload
          end
          specify do
            expect(page).to have_selector("h3", text: "Soumission (correcte)")
            expect(page).to have_selector("div", text: newcorrection2)
            expect(Following.where(:user => good_corrector, :submission => waiting_submission).first.first_corrector?).to eq(true)
            expect(Following.where(:user => good_corrector, :submission => waiting_submission).first.read).to eq(false)
            expect(Following.where(:user => admin, :submission => waiting_submission).first.other_corrector?).to eq(true)
            expect(Following.where(:user => admin, :submission => waiting_submission).first.read).to eq(true)
          end
        end
        
        describe "and user" do
          before do
            sign_out
            sign_in user
          end
          it { should have_link("1", href: notifs_path) }
          
          describe "visits answers page" do
            before { visit notifs_path }
            it do
              should have_selector("h1", text: "Nouvelles réponses")
              should have_link("Voir", href: problem_submission_path(problem_with_submissions, waiting_submission))
            end
          end
          
          describe "reads correction" do
            before { visit problem_submission_path(problem_with_submissions, waiting_submission) }
            it do
              should have_selector("h3", text: "Soumission (erronée)")
              should have_selector("div", text: newcorrection)
              should have_selector("div", text: "Votre solution est erronée.")
              should have_selector("h4", text: "Poster un commentaire")
              should have_no_link(href: notifs_path) # no more notification
            end
            
            describe "and revisits answers page" do
              before { visit notifs_path }
              it do
                should have_selector("h1", text: "Nouvelles réponses")
                should have_no_link("Voir", href: problem_submission_path(problem_with_submissions, waiting_submission))
              end
            end
            
            describe "and answers" do
              before do
                fill_in "MathInput", with: newanswer
                click_button "Poster"
                waiting_submission.reload
              end
              specify do
                expect(waiting_submission.wrong_to_read?).to eq(true)
                expect(waiting_submission.corrections.last.content).to eq(newanswer)
                expect(page).to have_selector("h3", text: "Soumission (erronée)")
                expect(page).to have_selector("div", text: newanswer)
              end
              
              describe "and corrector" do
                before do
                  sign_out
                  sign_in good_corrector
                end
                it do
                  should have_link("0", href: allnew_submissions_path(:levels => 3))
                  should have_link("0", href: allnew_submissions_path(:levels => 28))
                  should have_link("1", href: allmynew_submissions_path)
                end
                
                describe "visits comments page" do
                  before { visit allmynew_submissions_path }
                  it do
                    should have_selector("h1", text: "Commentaires")
                    should have_link(user.name, href: user_path(user))
                  end
                end
                
                describe "reads answer" do
                  before { visit problem_submission_path(problem_with_submissions, waiting_submission) }
                  it do
                    should have_selector("h3", text: "Soumission (erronée)")
                    should have_selector("div", text: newanswer)
                    should have_button("Poster et refuser la soumission")
                    should have_button("Poster et accepter la soumission")
                    should have_link("Marquer comme lu")
                    should have_no_link("Marquer comme non lu")
                  end
                  
                  describe "and marks as read" do
                    before { click_link "Marquer comme lu" }
                    it do
                      should have_link("Marquer comme non lu")
                      should have_no_link("Marquer comme lu")
                    end
                    
                    describe "and marks as unread" do
                      before { click_link "Marquer comme non lu" }
                      it do
                        should have_link("Marquer comme lu")
                        should have_no_link("Marquer comme non lu")
                      end
                    end
                  end
                  
                  describe "and accepts it" do
                    before do
                      Submission.create(user: user, problem: problem_with_submissions, status: :draft, content: "brouillon")
                      fill_in "MathInput", with: newcorrection2
                      click_button "Poster et accepter la soumission"
                      waiting_submission.reload
                    end
                    specify do
                      expect(waiting_submission.correct?).to eq(true)
                      expect(waiting_submission.corrections.last.content).to eq(newcorrection2)
                      expect(problem_with_submissions.submissions.where(:user => user, :status => :draft).count).to eq(0)
                      expect(page).to have_selector("h3", text: "Soumission (correcte)")
                      expect(page).to have_selector("div", text: newcorrection2)
                    end
                  end
                  
                  describe "and closes it" do
                    before do
                      fill_in "MathInput", with: newcorrection2
                      click_button "Poster et clôturer la soumission"
                      waiting_submission.reload
                    end
                    specify do
                      expect(waiting_submission.closed?).to eq(true)
                      expect(waiting_submission.corrections.last.content).to eq(newcorrection2)
                      expect(page).to have_selector("h3", text: "Soumission (clôturée)")
                      expect(page).to have_selector("div", text: newcorrection2)
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
    
    # -- TESTS THAT REQUIRE JAVASCRIPT --
    
    describe "wants to correct a submission", :js => true do
      before { visit problem_submission_path(problem_with_submissions, waiting_submission) }
      it do
        should have_selector("h3", text: "Soumission (en attente de correction)")
        should have_selector("div", text: waiting_submission.content)
        should have_content("Avant de corriger cette soumission, prévenez les autres que vous vous en occupez !")
        should have_button("Réserver cette soumission")
        should have_no_button("Annuler ma réservation")
      end
      
      describe "and hacks the system to unreserve a submission we did not reserve" do
        before do
          f = Following.create(:user => good_corrector, :submission => waiting_submission, :read => true, :kind => :reservation)
          visit problem_submission_path(problem_with_submissions, waiting_submission)
          f.update_attribute(:user, admin)
          click_button "Annuler ma réservation"
          wait_for_ajax
          waiting_submission.reload
        end
        specify do
          expect(waiting_submission.followings.count).to eq(1)
          expect(waiting_submission.followings.first.user).to eq(admin)
          expect(page).to have_content("Une erreur est survenue.")
        end
      end
      
      describe "and reserves it while somebody else reserved it" do
        before do
          Following.create(:user => admin, :submission => waiting_submission, :read => true, :kind => :reservation)
          click_button "Réserver cette soumission"
          wait_for_ajax
          waiting_submission.reload
        end
        specify do
          expect(page).to have_content("Cette soumission est en train d'être corrigée par #{admin.name}.")
          expect(page).to have_no_button("Réserver cette soumission")
          expect(page).to have_no_button("Annuler ma réservation")
          expect(page).to have_no_button("Annuler la réservation")
          expect(page).to have_button("Poster et refuser la soumission", disabled: true)
          expect(page).to have_button("Poster et accepter la soumission", disabled: true)
          expect(waiting_submission.followings.count).to eq(1)
          expect(waiting_submission.followings.first.user).to eq(admin)
        end
      end
      
      describe "and reserves it" do
        before do
          click_button "Réserver cette soumission"
          wait_for_ajax
          waiting_submission.reload
        end
        specify do
          expect(page).to have_content("Vous avez réservé cette soumission pour la corriger.")
          expect(page).to have_button("Annuler ma réservation")
          expect(page).to have_no_button("Annuler la réservation")
          expect(page).to have_button("Poster et refuser la soumission")
          expect(page).to have_button("Poster et accepter la soumission")
          expect(waiting_submission.followings.count).to eq(1)
          expect(waiting_submission.followings.first.user).to eq(good_corrector)
        end
          
        describe "and unreserves it" do
          before do
            click_button "Annuler ma réservation"
            wait_for_ajax
            waiting_submission.reload
          end
          specify do
            expect(page).to have_content("Avant de corriger cette soumission, prévenez les autres que vous vous en occupez !")
            expect(page).to have_button("Réserver cette soumission")
            expect(page).to have_no_button("Annuler ma réservation")
            expect(page).to have_no_button("Annuler la réservation")
            expect(page).to have_button("Poster et refuser la soumission", disabled: true)
            expect(page).to have_button("Poster et accepter la soumission", disabled: true)
            expect(waiting_submission.followings.count).to eq(0)
          end
        end
      end
    end
  end
  
  describe "root" do
    before { sign_in root }
    
    describe "visits next good submission" do
      before do
        visit problem_submission_path(problem_with_submissions, good_submission)
        click_link("Bonne solution suivante")
      end
      it { should have_content(good_corrector_submission.content) }
      
      describe "and click again" do
        before { click_link("Bonne solution suivante") }
        it do
          should have_info_message("Aucune soumission trouvée")
          should have_content(good_corrector_submission.content)
        end
      end
    end
    
    describe "visits previous good submission" do
      before do
        visit problem_submission_path(problem_with_submissions, good_corrector_submission)
        click_link("Bonne solution précédente")
      end
      it { should have_content(good_submission.content) }
      
      describe "and click again" do
        before { click_link("Bonne solution précédente") }
        it do
          should have_info_message("Aucune soumission trouvée")
          should have_content(good_submission.content)
        end
      end
    end
     
    describe "visits wrong submission" do
      before { visit problem_submission_path(problem_with_submissions, wrong_submission) }
      specify do
        expect(page).to have_link("Modifier la solution")
        expect(page).to have_link("Supprimer cette soumission")
        expect { click_link("Supprimer cette soumission") }.to change{problem_with_submissions.submissions.count}.by(-1)
      end
      
      describe "and updates it" do
        before do
          fill_in "MathInputSubmission", with: newsubmission2
          click_button "Enregistrer cette solution"
          wrong_submission.reload
        end
        specify do
          expect(page).to have_success_message("Solution modifiée.")
          expect(page).to have_selector("h3", text: "Soumission (erronée)")
          expect(page).to have_link("Modifier la solution")
          expect(wrong_submission.content).to eq(newsubmission2)
        end
      end
    end
    
    describe "gives a star to a submission" do
      before do
        visit problem_submission_path(problem_with_submissions, good_submission)
        click_link "Étoiler cette solution"
        good_submission.reload
      end
      specify { expect(good_submission.star).to eq(true) }
    end
    
    describe "removes a star from a submission" do
      before do
        good_submission.update_attribute(:star, true)
        visit problem_submission_path(problem_with_submissions, good_submission)
        click_link "Ne plus étoiler cette solution"
        good_submission.reload
      end
      specify { expect(good_submission.star).to eq(false) }
    end
    
    describe "marks a solution as wrong" do
      let!(:rating_before) { good_corrector.rating }
    
      before do
        visit problem_submission_path(problem_with_submissions, good_corrector_submission)
        click_link "Marquer comme erronée"
        good_corrector_submission.reload
        good_corrector.reload
      end
      specify do
        expect(good_corrector_submission.wrong?).to eq(true)
        expect(good_corrector.rating).to eq(rating_before - problem_with_submissions.value)
        expect(Solvedproblem.where(:user => good_corrector, :problem => problem_with_submissions).count).to eq(0)
      end
    end
    
    describe "visits reserved virtualtest submission" do
      let!(:virtualtest) { FactoryBot.create(:virtualtest, online: true, number: 12) }
      let!(:problem_in_test) { FactoryBot.create(:problem, virtualtest: virtualtest, section: section) }
      let!(:waiting_submission_in_test) { FactoryBot.create(:submission, problem: problem_in_test, user: user, status: :waiting, intest: true) }
      before do
        Takentest.create(:user => user, :virtualtest => virtualtest, :taken_time => DateTime.now - 2.weeks)
        Following.create(:user => root, :submission => waiting_submission_in_test, :read => true, :kind => :reservation)
        visit problem_submission_path(problem_in_test, waiting_submission_in_test)
      end
      it do
        should have_button("Poster et refuser la soumission")
        should have_button("Poster et accepter la soumission")
      end
      
      describe "and rejects it" do
        before do
          fill_in "MathInput", with: newcorrection
          fill_in "score", with: 4
          click_button "Poster et refuser la soumission"
          waiting_submission_in_test.reload
        end
        specify do
          expect(waiting_submission_in_test.wrong?).to eq(true)
          expect(waiting_submission_in_test.score).to eq(4)
          expect(page).to have_content("4 / 7")
        end
        
        describe "and modifies the score", :js => true do
          before do
            click_link "Modifier ce score"
            fill_in "new_score", with: 3
            click_button "Modifier"
            # No dialog box to accept in test environment: it was deactivated because we had issues with testing
            waiting_submission_in_test.reload
          end
          specify do
            expect(waiting_submission_in_test.score).to eq(3)
            expect(page).to have_content("3 / 7")
          end
        end
      end
      
      describe "and accepts it" do
        before do
          fill_in "MathInput", with: newcorrection
          fill_in "score", with: 7
          click_button "Poster et accepter la soumission"
          waiting_submission_in_test.reload
        end
        specify do
          expect(waiting_submission_in_test.correct?).to eq(true)
          expect(waiting_submission_in_test.score).to eq(7)
          expect(page).to have_content("7 / 7")
        end
      end
      
      describe "and corrects it without giving a score" do
        before do
          fill_in "MathInput", with: newcorrection
          click_button "Poster et refuser la soumission"
          waiting_submission_in_test.reload
        end
        specify do
          expect(page).to have_error_message("Veuillez donner un score à cette solution.")
          expect(waiting_submission_in_test.waiting?).to eq(true)
          expect(waiting_submission_in_test.score).to eq(-1)
        end
      end
      
      describe "and tries to accept it with a bad score" do
        before do
          fill_in "MathInput", with: newcorrection
          fill_in "score", with: 4
          click_button "Poster et accepter la soumission"
          waiting_submission_in_test.reload
        end
        specify do
          expect(page).to have_error_message("Vous ne pouvez pas accepter une solution sans lui donner un score de 6 ou 7.")
          expect(waiting_submission_in_test.waiting?).to eq(true)
          expect(waiting_submission_in_test.score).to eq(-1)
        end
      end
    end
    
    describe "visits a solution reserved by somebody else" do
      before do
        Following.create(:user => good_corrector, :submission => waiting_submission, :read => true, :kind => :reservation)
        visit problem_submission_path(problem_with_submissions, waiting_submission)
      end
      specify do
        expect(page).to have_content("Cette soumission est en train d'être corrigée par #{good_corrector.name}.")
        expect(page).to have_content("Réservée le ")
        expect(page).to have_no_button("Réserver cette soumission")
        expect(page).to have_no_button("Annuler ma réservation")
        expect(page).to have_button("Annuler la réservation")
        expect(page).to have_button("Poster et refuser la soumission", disabled: true)
        expect(page).to have_button("Poster et accepter la soumission", disabled: true)
      end
      
      # -- TESTS THAT REQUIRE JAVASCRIPT --
      
      describe "and unreserves it", :js => true do
        before do
          wait_for_js_imports
          click_button "Annuler la réservation"
          wait_for_ajax
          waiting_submission.reload
        end
        specify do
          expect(page).to have_content("Avant de corriger cette soumission, prévenez les autres que vous vous en occupez !")
          expect(page).to have_button("Réserver cette soumission")
          expect(page).to have_no_button("Annuler ma réservation")
          expect(page).to have_no_button("Annuler la réservation")
          expect(page).to have_button("Poster et refuser la soumission", disabled: true)
          expect(page).to have_button("Poster et accepter la soumission", disabled: true)
          expect(waiting_submission.followings.count).to eq(0)
        end
      end
    end
  end
  
  # -- TESTS THAT REQUIRE JAVASCRIPT --
  
  describe "user", :js => true do
    before { sign_in user }
  
    describe "creates a draft with a file" do
      before do
        visit new_problem_submission_path(problem)
        fill_in "MathInput", with: newsubmission
        wait_for_js_imports
        click_button "Ajouter une pièce jointe" # We don't fill file1
        wait_for_ajax
        click_button "Ajouter une pièce jointe"
        wait_for_ajax
        attach_file("file_2", File.absolute_path(attachments_folder + image1))
        click_button "Enregistrer cette solution"
      end
      let!(:newsub) { problem.submissions.order(:id).last }
      specify do
        expect(newsub.content).to eq(newsubmission)
        expect(newsub.myfiles.count).to eq(1)
        expect(newsub.myfiles.first.file.filename.to_s).to eq(image1)
      end
      
      describe "and updates it with a wrong file" do
        before do
          click_link "Modifier la solution"
          wait_for_ajax
          fill_in "MathInput", with: newsubmission2
          wait_for_js_imports
          click_button "Ajouter une pièce jointe"
          wait_for_ajax
          attach_file("file_1", File.absolute_path(attachments_folder + exe_attachment))
          click_button "Enregistrer cette solution"
          newsub.reload
        end
        specify do
          expect(page).to have_error_message("Votre pièce jointe '#{exe_attachment}' ne respecte pas les conditions")
          expect(newsub.content).to eq(newsubmission)
          expect(newsub.myfiles.count).to eq(1)
          expect(newsub.myfiles.first.file.filename.to_s).to eq(image1)
        end
      end
    end
  end
  
  describe "admin", :js => true do
    before { sign_in admin }
    
    describe "creates a correction with a file" do
      let!(:numfiles_before) { Myfile.count }
      before do
        visit problem_submission_path(problem_with_submissions, waiting_submission)
        wait_for_js_imports
        click_button "Réserver cette soumission"
        wait_for_ajax
        fill_in "MathInput", with: newcorrection
        click_button "Ajouter une pièce jointe"
        wait_for_ajax
        attach_file("file_1", File.absolute_path(attachments_folder + image1))
        click_button "Ajouter une pièce jointe"
        wait_for_ajax
        attach_file("file_2", File.absolute_path(attachments_folder + exe_attachment))
        click_button "Poster et refuser la soumission"
        waiting_submission.reload
      end
      specify do
        expect(waiting_submission.waiting?).to eq(true)
        expect(waiting_submission.corrections.count).to eq(0)
        expect(Myfile.count).to eq(numfiles_before)
      end
    end
    
    describe "shows correct submissions to a problem" do
      before do
        visit problem_path(problem_with_submissions)
        wait_for_js_imports
        click_link "Afficher les autres soumissions correctes"
        wait_for_ajax
      end
      it do
        should have_link(good_corrector.name, href: user_path(good_corrector))
        should have_link("Voir", href: problem_submission_path(problem_with_submissions, good_corrector_submission))
        should have_no_link("Voir", href: problem_submission_path(problem_with_submissions, wrong_submission))
      end
    end
    
    describe "shows incorrect submissions to a problem" do
      before do
        visit problem_path(problem_with_submissions)
        wait_for_js_imports
        click_link "Afficher les soumissions erronées"
        wait_for_ajax
      end
      it do
        should have_link(other_user.name, href: user_path(other_user))
        should have_link("Voir", href: problem_submission_path(problem_with_submissions, wrong_submission))
        should have_no_link("Voir", href: problem_submission_path(problem_with_submissions, good_corrector_submission))
      end
    end
    
    describe "search for a string in submissions" do
      before do
        waiting_submission.update_attribute(:content, "Bonjour, voici   une solution")
        wrong_submission.update_attribute(:content, "Voici une autre solution")
        Correction.create(user: other_user, submission: wrong_submission, content: "Bonjour, ceci est ma correction")
        good_corrector_submission.update_attribute(:content, "Salut, ceci est ma solution")
        visit problem_submission_path(problem_with_submissions, waiting_submission)
        wait_for_js_imports
        click_link "Effectuer une recherche dans toutes les soumissions"
        wait_for_ajax
        fill_in "string_to_search", with: "Bonjour, "
        check "search_in_comments"
        click_button "Chercher"
        wait_for_ajax
      end
      it do
        should have_link(user.name, href: user_path(user))
        should have_content("Bonjour, voici une solution")
        should have_link("Voir", href: problem_submission_path(problem_with_submissions, waiting_submission))
        should have_link(other_user.name, href: user_path(other_user))
        should have_content("Bonjour, ceci est ma correction")
        should have_link("Voir", href: problem_submission_path(problem_with_submissions, wrong_submission))
        should have_no_link(good_corrector.name, href: user_path(good_corrector))
        should have_no_content("Salut, ceci est ma solution")
        should have_no_link("Voir", href: problem_submission_path(problem_with_submissions, good_corrector_submission))
      end
    end
  end
end
