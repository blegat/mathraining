# -*- coding: utf-8 -*-
require "spec_helper"

describe "Submission pages" do

  subject { page }

  let(:admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user, rating: 200) }
  let(:good_corrector) { FactoryGirl.create(:corrector) }
  let(:bad_corrector) { FactoryGirl.create(:corrector) }
  let!(:problem) { FactoryGirl.create(:problem, online: true) }
  let!(:problem_with_waiting_submission) { FactoryGirl.create(:problem, online: true) }
  let!(:waiting_submission) { FactoryGirl.create(:submission, problem: problem_with_waiting_submission, user: user, status: 0) } 
  
  let!(:good_corrector_submission) { FactoryGirl.create(:submission, problem: problem_with_waiting_submission, user: good_corrector, status: 2) }
  let!(:good_corrector_solvedproblem) { FactoryGirl.create(:solvedproblem, problem: problem_with_waiting_submission, submission: good_corrector_submission, user: good_corrector) }
  
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
      before { visit problem_path(problem.id) }
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
        
        describe "and sends new submission" do
          before do
            fill_in "MathInput", with: newsubmission
            click_button "Soumettre cette solution"
          end
          specify do
            expect(problem.submissions.order(:id).last.content).to eq(newsubmission)
            expect(problem.submissions.order(:id).last.status).to eq(0)
          end
          it do
            should have_selector("h3", text: "Soumission (en attente de correction)")
            should have_selector("div", text: newsubmission)
          end
        end
        
        describe "and saves as draft" do
          before do
            fill_in "MathInput", with: newsubmission
            click_button "Enregistrer comme brouillon"
          end
          specify do
            expect(problem.submissions.order(:id).last.content).to eq(newsubmission)
            expect(problem.submissions.order(:id).last.status).to eq(-1)
          end
          it do
            should have_selector("h3", text: "Nouvelle soumission")
            should have_button("Soumettre cette solution")
            should have_button("Enregistrer le brouillon")
            should have_button("Supprimer ce brouillon")
          end
          
          specify { expect { click_button "Supprimer ce brouillon" }.to change(Submission, :count).by(-1) }
          
          describe "and updates the draft" do
            before do
              fill_in "MathInput", with: newsubmission2
              click_button "Enregistrer le brouillon"
            end
            specify do
              expect(problem.submissions.order(:id).last.content).to eq(newsubmission2)
              expect(problem.submissions.order(:id).last.status).to eq(-1)
            end
            it { should have_selector("h3", text: "Nouvelle soumission") }
          end
          
          describe "and sends the draft as submission" do
            before do
              fill_in "MathInput", with: newsubmission2
              click_button "Soumettre cette solution"
            end
            specify do
              expect(problem.submissions.order(:id).last.content).to eq(newsubmission2)
              expect(problem.submissions.order(:id).last.status).to eq(0)
            end
            it do
              should have_selector("h3", text: "Soumission (en attente de correction)")
              should have_selector("div", text: newsubmission2)
            end
          end
        end
      end
    end
  end
  
  describe "bad corrector" do
    before { sign_in bad_corrector }
    it { should have_link("0", href: allnewsub_path) } # 0 waiting submission (because cannot see it)
    
    describe "visits submissions page" do
      before { visit allnewsub_path }
      it do
        should have_selector("h1", text: "Soumissions")
        should have_no_link(user.name, href: user_path(user.id))
      end
    end
     
    describe "visits waiting submission" do
      before { visit problem_path(problem_with_waiting_submission, :sub => waiting_submission.id) }
      it do
        should have_no_selector("h3", text: "Soumission (en attente de correction)")
        should have_no_selector("div", text: waiting_submission.content)
      end
    end
  end
    
  describe "good corrector" do
    before { sign_in good_corrector }
    it { should have_link("1", href: allnewsub_path) } # 1 waiting submission
    
    describe "visits submissions page" do
      before { visit allnewsub_path }
      it do
        should have_selector("h1", text: "Soumissions")
        should have_link(user.name, href: user_path(user))
      end
    end
    
    describe "visits waiting submission" do
      before { visit problem_path(problem_with_waiting_submission, :sub => waiting_submission) }
      it do
        should have_selector("h3", text: "Soumission (en attente de correction)")
        should have_selector("div", text: waiting_submission.content)
        should have_button("Poster et refuser la soumission", disabled: true) # Because not reserved
        should have_button("Poster et accepter la soumission", disabled: true) # Because not reserved
      end
      
      describe "and reserves it (fictively)" do
        before do
          f = Following.new
          f.user = good_corrector
          f.submission = waiting_submission
          f.read = true
          f.kind = 0
          f.save
          visit problem_path(problem_with_waiting_submission, :sub => waiting_submission) # Reload
        end
        it do
          should have_button("Poster et refuser la soumission")
          should have_button("Poster et accepter la soumission")
        end
        
        describe "and accepts it" do
          before do
            fill_in "MathInput", with: newcorrection
            click_button "Poster et accepter la soumission"
            waiting_submission.reload
          end
          specify do
            expect(waiting_submission.status).to eq(2)
            expect(waiting_submission.corrections.last.content).to eq(newcorrection)
          end
          it do
            should have_selector("h3", text: "Soumission (correcte)")
            should have_selector("div", text: newcorrection)
            should have_link("0", href: allnewsub_path) # no more waiting submission
          end
        end
        
        describe "and rejects it" do
          before do
            fill_in "MathInput", with: newcorrection
            click_button "Poster et refuser la soumission"
            waiting_submission.reload
          end
          specify do
            expect(waiting_submission.status).to eq(1)
            expect(waiting_submission.corrections.last.content).to eq(newcorrection)
          end
          it do
            should have_selector("h3", text: "Soumission (erronée)")
            should have_selector("div", text: newcorrection)
            should have_link("0", href: allnewsub_path) # no more waiting submission
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
                should have_link("Voir", href: problem_path(problem_with_waiting_submission, :sub => waiting_submission))
              end
            end
            
            describe "reads correction" do
              before { visit problem_path(problem_with_waiting_submission, :sub => waiting_submission) }
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
                  should have_no_link("Voir", href: problem_path(problem_with_waiting_submission, :sub => waiting_submission))
                end
              end
              
              describe "and answers" do
                before do
                  fill_in "MathInput", with: newanswer
                  click_button "Poster"
                  waiting_submission.reload
                end
                specify do
                  expect(waiting_submission.status).to eq(3)
                  expect(waiting_submission.corrections.last.content).to eq(newanswer)
                end
                it do
                  should have_selector("h3", text: "Soumission (erronée)")
                  should have_selector("div", text: newanswer)
                end
                
                describe "and corrector" do
                  before do
                    sign_out
                    sign_in good_corrector
                  end
                  it do
                    should have_link("0", href: allnewsub_path)
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
                    before { visit problem_path(problem_with_waiting_submission, :sub => waiting_submission) }
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
                        expect(waiting_submission.status).to eq(2)
                        expect(waiting_submission.corrections.last.content).to eq(newcorrection2)
                      end
                      it do
                        should have_selector("h3", text: "Soumission (correcte)")
                        should have_selector("div", text: newcorrection2)
                      end
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
      before { visit problem_path(problem_with_waiting_submission, :sub => waiting_submission) }
      it do
        should have_selector("h3", text: "Soumission (en attente de correction)")
        should have_selector("div", text: waiting_submission.content)
        should have_content("Avant de corriger cette soumission, prévenez les autres que vous vous en occupez !")
        should have_button("Réserver cette soumission")
        should have_no_button("Annuler ma réservation")
      end
      
      describe "and hacks the system to unreserve a submission we did not reserve" do
        before do
          f = Following.new
          f.user = good_corrector
          f.submission = waiting_submission
          f.read = true
          f.kind = 0
          f.save
          visit problem_path(problem_with_waiting_submission, :sub => waiting_submission)
          f.user = admin
          f.save
          click_button "Annuler ma réservation"
          wait_for_ajax
          waiting_submission.reload
        end
        it { should have_content("Une erreur est survenue.") }
        specify do
          expect(waiting_submission.followings.count).to eq(1)
          expect(waiting_submission.followings.first.user).to eq(admin)
        end
      end
      
      describe "and reserves it while somebody else reserved it" do
        before do
          f = Following.new
          f.user = admin
          f.submission = waiting_submission
          f.read = true
          f.kind = 0
          f.save
          click_button "Réserver cette soumission"
          wait_for_ajax
          waiting_submission.reload
        end
        it do
          should have_content("Cette soumission est en train d'être corrigée par #{admin.name}.")
          should have_no_button("Réserver cette soumission")
          should have_no_button("Annuler ma réservation")
          should have_button("Poster et refuser la soumission", disabled: true)
          should have_button("Poster et accepter la soumission", disabled: true)
        end
        specify do
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
        it do
          should have_content("Vous avez réservé cette soumission pour la corriger.")
          should have_button("Annuler ma réservation")
          should have_button("Poster et refuser la soumission")
          should have_button("Poster et accepter la soumission")
        end
        specify do
          expect(waiting_submission.followings.count).to eq(1)
          expect(waiting_submission.followings.first.user).to eq(good_corrector)
        end
          
        describe "and unreserves it" do
          before do
            click_button "Annuler ma réservation"
            wait_for_ajax
            waiting_submission.reload
          end
          it do
            should have_content("Avant de corriger cette soumission, prévenez les autres que vous vous en occupez !")
            should have_button("Réserver cette soumission")
            should have_no_button("Annuler ma réservation")
            should have_button("Poster et refuser la soumission", disabled: true)
            should have_button("Poster et accepter la soumission", disabled: true)
          end
          specify { expect(waiting_submission.followings.count).to eq(0) }
        end
      end
    end
  end
  
  # -- TESTS THAT REQUIRE JAVASCRIPT --
  
  describe "user", :js => true do
    before { sign_in user }
  
    describe "creates a submission with a file" do
      before do
        visit problem_path(problem, :sub => 0)
        fill_in "MathInput", with: newsubmission
        click_button "Ajouter une pièce jointe" # We don't fill file1
        wait_for_ajax
        click_button "Ajouter une pièce jointe"
        wait_for_ajax
        attach_file("file_2", File.absolute_path(attachments_folder + image1))
        check "consent"
        click_button "Soumettre cette solution"
        accept_browser_dialog
      end
      let(:newsub) { problem.submissions.order(:id).last }
      specify do
        expect(newsub.content).to eq(newsubmission)
        expect(newsub.myfiles.count).to eq(1)
        expect(newsub.myfiles.first.file.filename.to_s).to eq(image1)
      end
    end
  end
  
  describe "admin", :js => true do
    before { sign_in admin }
    
    describe "creates a correction with a file" do
      let!(:numfiles_before) { Myfile.count }
      before do
        visit problem_path(problem_with_waiting_submission, :sub => waiting_submission)
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
        expect(waiting_submission.status).to eq(0)
        expect(waiting_submission.corrections.count).to eq(0)
        expect(Myfile.count).to eq(numfiles_before)
      end
    end
  end
end
