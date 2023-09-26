# -*- coding: utf-8 -*-
require "spec_helper"

describe "Submission pages" do

  subject { page }

  let(:root) { FactoryGirl.create(:root) }
  let(:admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user, rating: 200) }
  let(:other_user) { FactoryGirl.create(:user, rating: 200) }
  let(:other_user2) { FactoryGirl.create(:user, rating: 200) }
  let(:good_corrector) { FactoryGirl.create(:corrector) }
  let(:bad_corrector) { FactoryGirl.create(:corrector) }
  
  let!(:problem) { FactoryGirl.create(:problem, online: true, :level => 1) }
  let!(:problem_with_submissions) { FactoryGirl.create(:problem, online: true, :level => 1) }
  
  let!(:waiting_submission) { FactoryGirl.create(:submission, problem: problem_with_submissions, user: user, status: :waiting) } 
  let!(:wrong_submission) { FactoryGirl.create(:submission, problem: problem_with_submissions, user: other_user, status: :wrong) }
  let!(:good_submission) { FactoryGirl.create(:submission, problem: problem_with_submissions, user: other_user2, status: :correct) }
  let!(:good_solvedproblem) { FactoryGirl.create(:solvedproblem, problem: problem_with_submissions, submission: good_submission, user: other_user2) }
  
  let!(:good_corrector_submission) { FactoryGirl.create(:submission, problem: problem_with_submissions, user: good_corrector, status: :correct) }
  let!(:good_corrector_solvedproblem) { FactoryGirl.create(:solvedproblem, problem: problem_with_submissions, submission: good_corrector_submission, user: good_corrector) }
  
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
      
      describe "and visits new submission page" do
        before { click_link("Nouvelle soumission") }
        it do
          should have_selector("h3", text: "Énoncé")
          should have_selector("h3", text: "Nouvelle soumission")
          should have_button("Soumettre cette solution")
          should have_button("Enregistrer comme brouillon")
        end
        
        describe "and sends new empty submission" do
          before do
            fill_in "MathInput", with: ""
            click_button "Soumettre cette solution"
          end
          it { should have_error_message("Soumission doit être rempli") }
        end
        
        describe "and sends new submission" do
          before do
            fill_in "MathInput", with: newsubmission
            click_button "Soumettre cette solution"
          end
          specify do
            expect(page).to have_success_message("Votre solution a bien été soumise.")
            expect(page).to have_selector("h3", text: "Soumission (en attente de correction)")
            expect(page).to have_selector("div", text: newsubmission)
            expect(problem.submissions.order(:id).last.content).to eq(newsubmission)
            expect(problem.submissions.order(:id).last.waiting?).to eq(true)
          end
        end
        
        describe "and sends new submission while one is already waiting" do # Can only be done with several tabs
          before do
            FactoryGirl.create(:submission, problem: problem, user: user, status: :waiting)
            fill_in "MathInput", with: newsubmission
            click_button "Soumettre cette solution"
          end
          specify do
            expect(page).to have_selector("h1", text: "Problème ##{problem.number}")
            expect(page).to have_no_link("Nouvelle soumission")
            expect(problem.submissions.order(:id).last.content).not_to eq(newsubmission)
            expect(problem.submissions.where(:user => user).count).to eq(1) # Only the one created by FactoryGirl 
          end
        end
        
        describe "and sends new submission while another one was recently plagiarized" do # Can only be done with several tabs
          before do
            FactoryGirl.create(:submission, problem: problem, user: user, status: :plagiarized, last_comment_time: DateTime.now - 3.months)
            fill_in "MathInput", with: newsubmission
            click_button "Soumettre cette solution"
          end
          specify do
            expect(page).to have_selector("h1", text: "Problème ##{problem.number}")
            expect(page).to have_no_link("Nouvelle soumission")
            expect(page).to have_content("Vous avez soumis une solution plagiée à ce problème.")
            expect(problem.submissions.order(:id).last.content).not_to eq(newsubmission)
            expect(problem.submissions.where(:user => user).count).to eq(1) # Only the plagiarized one created by FactoryGirl 
          end
        end
        
        describe "and sends new submission while another one was plagiarized long ago" do
          before do
            FactoryGirl.create(:submission, problem: problem, user: user, status: :plagiarized, last_comment_time: DateTime.now - 2.years)
            fill_in "MathInput", with: newsubmission
            click_button "Soumettre cette solution"
          end
          specify do
            expect(page).to have_selector("h1", text: "Problème ##{problem.number}")
            expect(page).to have_no_content("Vous avez soumis une solution plagiée à ce problème.") # not shown for old plagiarism
            expect(page).to have_success_message("Votre solution a bien été soumise.")
            expect(page).to have_selector("h3", text: "Soumission (en attente de correction)")
            expect(page).to have_selector("div", text: newsubmission)
          end
        end
        
        describe "and saves as draft" do
          before do
            fill_in "MathInput", with: newsubmission
            click_button "Enregistrer comme brouillon"
          end
          let!(:submission) { problem.submissions.order(:id).last }
          specify do
            expect(page).to have_success_message("Votre brouillon a bien été enregistré.")
            expect(page).to have_selector("h3", text: "Nouvelle soumission")
            expect(page).to have_button("Soumettre cette solution")
            expect(page).to have_button("Enregistrer le brouillon")
            expect(page).to have_button("Supprimer ce brouillon")
            expect(submission.content).to eq(newsubmission)
            expect(submission.draft?).to eq(true)
          end
        end
      end
    end
      
    describe "visits problem with a draft" do
      let!(:draft_submission) { FactoryGirl.create(:submission, problem: problem, user: user, status: :draft, content: newsubmission) }
      before { visit problem_path(problem) }
      it do
        should have_selector("h1", text: "Problème ##{problem.number}")
        should have_selector("div", text: problem.statement)
        should have_link("Reprendre le brouillon")
      end
      
      describe "and visits draft page" do
        before { click_link "Reprendre le brouillon" }
        it do
          should have_selector("h3", text: "Énoncé")
          should have_selector("h3", text: "Nouvelle soumission")
          should have_button("Soumettre cette solution")
          should have_button("Enregistrer le brouillon")
          should have_button("Soumettre cette solution")
        end
          
        specify { expect { click_button "Supprimer ce brouillon" }.to change(Submission, :count).by(-1) }
          
        describe "and updates the draft" do
          before do
            fill_in "MathInput", with: newsubmission2
            click_button "Enregistrer le brouillon"
            draft_submission.reload
          end
          specify do
            expect(page).to have_success_message("Votre brouillon a bien été enregistré.")
            expect(page).to have_selector("h3", text: "Nouvelle soumission")
            expect(draft_submission.content).to eq(newsubmission2)
            expect(draft_submission.draft?).to eq(true)
          end
        end
        
        describe "and updates the draft for an empty draft" do
          before do
            fill_in "MathInput", with: ""
            click_button "Enregistrer le brouillon"
            draft_submission.reload
          end
          specify do
            expect(page).to have_error_message("Soumission doit être rempli")
            expect(draft_submission.content).to eq(newsubmission)
            expect(draft_submission.draft?).to eq(true)
          end
        end
        
        describe "and sends the draft as submission" do
          before do
            fill_in "MathInput", with: newsubmission2
            click_button "Soumettre cette solution"
            draft_submission.reload
          end
          specify do
            expect(page).to have_success_message("Votre solution a bien été soumise.")
            expect(page).to have_selector("h3", text: "Soumission (en attente de correction)")
            expect(page).to have_selector("div", text: newsubmission2)
            expect(draft_submission.content).to eq(newsubmission2)
            expect(draft_submission.waiting?).to eq(true)
          end
        end
        
        describe "and tries to update the draft of somebody else (hack)" do # Not possible without hack
          before do
            draft_submission.update_attribute(:user, other_user)
            fill_in "MathInput", with: newsubmission2
            click_button "Enregistrer le brouillon"
            draft_submission.reload
          end
          specify do
            expect(page).to have_content(error_access_refused)
            expect(draft_submission.content).to eq(newsubmission)
            expect(draft_submission.draft?).to eq(true)
          end
        end
        
        describe "and tries to update a draft that is already sent (hack)" do # Can only be done with several tabs
          before do
            draft_submission.waiting!
            fill_in "MathInput", with: newsubmission2
            click_button "Enregistrer le brouillon"
            draft_submission.reload
          end
          specify do
            expect(page).to_not have_success_message("Votre brouillon a bien été enregistré.")
            expect(page).to have_selector("h1", text: "Problème ##{problem.number}") # We simply redirect in this case (because it could happen)
            expect(draft_submission.content).to eq(newsubmission)
            expect(draft_submission.waiting?).to eq(true)
          end
        end
      end
    end
    
    describe "sends a submission to a virtualtest problem (later)" do
      let!(:virtualtest) { FactoryGirl.create(:virtualtest, online: true) }
      let!(:takentest) { Takentest.create(virtualtest: virtualtest, user: user, status: :finished) }
      before do
        problem.update_attribute(:virtualtest, virtualtest)
        visit problem_path(problem)
        click_link("Nouvelle soumission")
        fill_in "MathInput", with: newsubmission
        click_button "Soumettre cette solution"
      end
      specify do
        expect(problem.submissions.order(:id).last.content).to eq(newsubmission)
        expect(problem.submissions.order(:id).last.waiting?).to eq(true)
        expect(page).to have_selector("h3", text: "Soumission (en attente de correction)")
        expect(page).to have_selector("div", text: newsubmission)
      end
    end
  end
  
  describe "bad corrector" do
    before { sign_in bad_corrector }
    it { should have_link("0", href: allnewsub_path(:levels => 3)) } # 0 waiting submission of level 1, 2 (because cannot see it)
    
    describe "visits submissions page" do
      before { visit allnewsub_path(:levels => 3) }
      it do
        should have_selector("h1", text: "Soumissions")
        should have_no_link(user.name, href: user_path(user))
      end
    end
     
    describe "visits waiting submission" do
      before { visit problem_path(problem_with_submissions, :sub => waiting_submission) }
      it do
        should have_no_selector("h3", text: "Soumission (en attente de correction)")
        should have_no_selector("div", text: waiting_submission.content)
      end
    end
  end
    
  describe "good corrector" do
    before { sign_in good_corrector }
    it { should have_link("1", href: allnewsub_path(:levels => 3)) } # 1 waiting submission
    
    describe "visits submissions page" do
      before { visit allnewsub_path(:levels => 3) }
      it do
        should have_selector("h1", text: "Soumissions")
        should have_link(user.name, href: user_path(user))
      end
    end
    
    describe "visits problem with waiting submission" do
      before { visit problem_path(problem_with_submissions) }
      it do
        should have_link("Voir", href: problem_path(problem_with_submissions, :sub => good_corrector_submission))
        should have_link("Voir", href: problem_path(problem_with_submissions, :sub => waiting_submission))
        should have_no_link("Voir", href: problem_path(problem_with_submissions, :sub => wrong_submission))
      end
    end
    
    describe "visits waiting submission" do
      before { visit problem_path(problem_with_submissions, :sub => waiting_submission) }
      it do
        should have_selector("h3", text: "Soumission (en attente de correction)")
        should have_selector("div", text: waiting_submission.content)
        should have_button("Poster et refuser la soumission", disabled: true) # Because not reserved
        should have_button("Poster et accepter la soumission", disabled: true) # Because not reserved
      end
    end
      
    describe "visits reserved waiting submission" do
      before do
        Following.create(user: good_corrector, submission: waiting_submission, read: true, kind: 0)
        visit problem_path(problem_with_submissions, :sub => waiting_submission) # Reload
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
          expect(page).to have_link("0", href: allnewsub_path(:levels => 3)) # no more waiting submission
          expect(page).to have_link("Marquer comme erronée")
          expect(page).not_to have_link("Étoiler cette solution") # only for roots
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
            expect(page).not_to have_link("Marquer comme erronée")
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
            expect(page).not_to have_link("Marquer comme erronée") # Because too late
            expect(user.rating).to eq(rating_before + waiting_submission.problem.value)
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
          FactoryGirl.create(:correction, submission: waiting_submission, user: user, content: "J'ajoute une précision")
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
        before do
          fill_in "MathInput", with: newcorrection
          click_button "Poster et refuser la soumission"
          waiting_submission.reload
        end
        specify do
          expect(waiting_submission.wrong?).to eq(true)
          expect(waiting_submission.corrections.last.content).to eq(newcorrection)
          expect(page).to have_selector("h3", text: "Soumission (erronée)")
          expect(page).to have_selector("div", text: newcorrection)
          expect(page).to have_link("0", href: allnewsub_path(:levels => 3)) # no more waiting submission
        end
        
        describe "and user" do
          before do
            sign_out
            sign_in user
          end
          it { should have_link("1", href: notifs_show_path) }
          
          describe "visits answers page" do
            before { visit notifs_show_path }
            it do
              should have_selector("h1", text: "Nouvelles réponses")
              should have_link("Voir", href: problem_path(problem_with_submissions, :sub => waiting_submission))
            end
          end
          
          describe "reads correction" do
            before { visit problem_path(problem_with_submissions, :sub => waiting_submission) }
            it do
              should have_selector("h3", text: "Soumission (erronée)")
              should have_selector("div", text: newcorrection)
              should have_selector("div", text: "Votre solution est erronée.")
              should have_selector("h4", text: "Poster un commentaire")
              should have_no_link(href: notifs_show_path) # no more notification
            end
            
            describe "visits answers page" do
              before { visit notifs_show_path }
              it do
                should have_selector("h1", text: "Nouvelles réponses")
                should have_no_link("Voir", href: problem_path(problem_with_submissions, :sub => waiting_submission))
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
                  should have_link("0", href: allnewsub_path(:levels => 3))
                  should have_link("0", href: allnewsub_path(:levels => 28))
                  should have_link("1", href: allmynewsub_path)
                end
                
                describe "visits comments page" do
                  before { visit allmynewsub_path }
                  it do
                    should have_selector("h1", text: "Commentaires")
                    should have_link(user.name, href: user_path(user))
                  end
                end
                
                describe "reads answer" do
                  before { visit problem_path(problem_with_submissions, :sub => waiting_submission) }
                  it do
                    should have_selector("h3", text: "Soumission (erronée)")
                    should have_selector("div", text: newanswer)
                    should have_button("Poster et laisser la soumission comme erronée")
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
                      fill_in "MathInput", with: newcorrection2
                      click_button "Poster et accepter la soumission"
                      waiting_submission.reload
                    end
                    specify do
                      expect(waiting_submission.correct?).to eq(true)
                      expect(waiting_submission.corrections.last.content).to eq(newcorrection2)
                      expect(page).to have_selector("h3", text: "Soumission (correcte)")
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
      before { visit problem_path(problem_with_submissions, :sub => waiting_submission) }
      it do
        should have_selector("h3", text: "Soumission (en attente de correction)")
        should have_selector("div", text: waiting_submission.content)
        should have_content("Avant de corriger cette soumission, prévenez les autres que vous vous en occupez !")
        should have_button("Réserver cette soumission")
        should have_no_button("Annuler ma réservation")
      end
      
      describe "and hacks the system to unreserve a submission we did not reserve" do
        before do
          f = Following.create(:user => good_corrector, :submission => waiting_submission, :read => true, :kind => 0)
          visit problem_path(problem_with_submissions, :sub => waiting_submission)
          f.user = admin
          f.save
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
          Following.create(:user => admin, :submission => waiting_submission, :read => true, :kind => 0)
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
     
    describe "visits wrong submission" do
      before { visit problem_path(problem_with_submissions, :sub => wrong_submission) }
      specify do
        expect(page).to have_link("Supprimer cette soumission")
        expect { click_link("Supprimer cette soumission") }.to change{problem_with_submissions.submissions.count}.by(-1)
      end
    end
    
    describe "gives a star to a submission" do
      before do
        visit problem_path(problem_with_submissions, :sub => good_submission)
        click_button "Étoiler cette solution"
        good_submission.reload
      end
      specify { expect(good_submission.star).to eq(true) }
    end
    
    describe "removes a star from a submission" do
      before do
        good_submission.update_attribute(:star, true)
        visit problem_path(problem_with_submissions, :sub => good_submission)
        click_button "Ne plus étoiler cette solution"
        good_submission.reload
      end
      specify { expect(good_submission.star).to eq(false) }
    end
    
    describe "marks a solution as wrong" do
      let!(:rating_before) { good_corrector.rating }
    
      describe "when it was the only correct solution" do
        before do
          visit problem_path(problem_with_submissions, :sub => good_corrector_submission)
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
    
      describe "when there is another correct submission" do
        let!(:other_correct_submission) { FactoryGirl.create(:submission, problem: problem_with_submissions, user: good_corrector, status: :correct, created_at: DateTime.now - 2.weeks) }
        let!(:other_correction) { FactoryGirl.create(:correction, submission: other_correct_submission, user: root, created_at: DateTime.now - 1.week) }
        before do
          visit problem_path(problem_with_submissions, :sub => good_corrector_submission)
          click_link "Marquer comme erronée"
          good_corrector_submission.reload
          good_corrector.reload
          good_corrector_solvedproblem.reload
        end
        specify do
          expect(good_corrector_submission.wrong?).to eq(true)
          expect(good_corrector.rating).to eq(rating_before)
          expect(good_corrector_solvedproblem.submission).to eq(other_correct_submission)
          # NB: We need be_within(1.second) below, see https://stackoverflow.com/questions/20403063/trouble-comparing-time-with-rspec
          expect(good_corrector_solvedproblem.correction_time).to be_within(1.second).of other_correction.created_at
          expect(good_corrector_solvedproblem.resolution_time).to be_within(1.second).of other_correct_submission.created_at
        end
      end
    end
    
    describe "visits reserved virtualtest submission" do
      let!(:virtualtest) { FactoryGirl.create(:virtualtest, online: true, number: 12) }
      let!(:problem_in_test) { FactoryGirl.create(:problem, virtualtest: virtualtest) }
      let!(:waiting_submission_in_test) { FactoryGirl.create(:submission, problem: problem_in_test, user: user, status: :waiting, intest: true) }
      before do
        Takentest.create(user: user, virtualtest: virtualtest, taken_time: DateTime.now - 2.weeks)
        Following.create(user: root, submission: waiting_submission_in_test, read: true, kind: 0)
        visit problem_path(problem_in_test, :sub => waiting_submission_in_test)
      end
      it do
        should have_button("Poster et refuser la soumission")
        should have_button("Poster et accepter la soumission")
      end
      
      describe "and corrects it" do
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
    end
    
    describe "visits a solution reserved by somebody else" do
      before do
        Following.create(:user => good_corrector, :submission => waiting_submission, :read => true, :kind => 0)
        visit problem_path(problem_with_submissions, :sub => waiting_submission)
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
        visit problem_path(problem, :sub => 0)
        fill_in "MathInput", with: newsubmission
        click_button "Ajouter une pièce jointe" # We don't fill file1
        wait_for_ajax
        click_button "Ajouter une pièce jointe"
        wait_for_ajax
        attach_file("file_2", File.absolute_path(attachments_folder + image1))
        click_button "Enregistrer comme brouillon"
      end
      let!(:newsub) { problem.submissions.order(:id).last }
      specify do
        expect(newsub.content).to eq(newsubmission)
        expect(newsub.myfiles.count).to eq(1)
        expect(newsub.myfiles.first.file.filename.to_s).to eq(image1)
      end
      
      describe "and updates it with a wrong file" do
        before do
          fill_in "MathInput", with: newsubmission2
          click_button "Ajouter une pièce jointe"
          attach_file("file_1", File.absolute_path(attachments_folder + exe_attachment))
          click_button "Enregistrer le brouillon"
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
    
    describe "creates a submission with a wrong file" do
      before do
        visit problem_path(problem, :sub => 0)
        fill_in "MathInput", with: newsubmission
        click_button "Ajouter une pièce jointe"
        wait_for_ajax
        attach_file("file_1", File.absolute_path(attachments_folder + image2))
        click_button "Ajouter une pièce jointe"
        wait_for_ajax
        attach_file("file_2", File.absolute_path(attachments_folder + exe_attachment))
        check "consent"
        click_button "Soumettre cette solution"
        # No dialog box to accept in test environment: it was deactivated because we had issues with testing
      end
      it do
        should have_error_message("Votre pièce jointe '#{exe_attachment}' ne respecte pas les conditions")
        should have_selector("textarea", text: newsubmission)
      end
    end
  end
  
  describe "admin", :js => true do
    before { sign_in admin }
    
    describe "creates a correction with a file" do
      let!(:numfiles_before) { Myfile.count }
      before do
        visit problem_path(problem_with_submissions, :sub => waiting_submission)
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
        click_link "Afficher les autres soumissions correctes"
        wait_for_ajax
      end
      it do
        should have_link(good_corrector.name, href: user_path(good_corrector))
        should have_link("Voir", href: problem_path(problem_with_submissions, :sub => good_corrector_submission))
        should have_no_link("Voir", href: problem_path(problem_with_submissions, :sub => wrong_submission))
      end
    end
    
    describe "shows incorrect submissions to a problem" do
      before do
        visit problem_path(problem_with_submissions)
        click_link "Afficher les soumissions erronées"
        wait_for_ajax
      end
      it do
        should have_link(other_user.name, href: user_path(other_user))
        should have_link("Voir", href: problem_path(problem_with_submissions, :sub => wrong_submission))
        should have_no_link("Voir", href: problem_path(problem_with_submissions, :sub => good_corrector_submission))
      end
    end
    
    describe "search for a string in submissions" do
      before do
        waiting_submission.update_attribute(:content, "Bonjour, voici une solution")
        wrong_submission.update_attribute(:content, "Voici une autre solution")
        Correction.create(user: other_user, submission: wrong_submission, content: "Bonjour, ceci est ma correction")
        good_corrector_submission.update_attribute(:content, "Salut, ceci est ma solution")
        visit problem_path(problem_with_submissions, :sub => waiting_submission)
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
        should have_link("Voir", href: problem_path(problem_with_submissions, :sub => waiting_submission))
        should have_link(other_user.name, href: user_path(other_user))
        should have_content("Bonjour, ceci est ma correction")
        should have_link("Voir", href: problem_path(problem_with_submissions, :sub => wrong_submission))
        should have_no_link(good_corrector.name, href: user_path(good_corrector))
        should have_no_content("Salut, ceci est ma solution")
        should have_no_link("Voir", href: problem_path(problem_with_submissions, :sub => good_corrector_submission))
      end
    end
  end
end
