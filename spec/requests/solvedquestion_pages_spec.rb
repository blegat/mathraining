# -*- coding: utf-8 -*-
require "spec_helper"

describe "Solvedquestion pages" do

  subject { page }

  let(:user) { FactoryGirl.create(:user) }
  let!(:section) { FactoryGirl.create(:section) }
  let!(:chapter) { FactoryGirl.create(:chapter, section: section, online: true) }
  let!(:exercise) { FactoryGirl.create(:exercise, chapter: chapter, online: true, position: 1, level: 1) }
  let!(:exercise_decimal) { FactoryGirl.create(:exercise_decimal, chapter: chapter, online: true, position: 2, level: 2) }
  let!(:qcm) { FactoryGirl.create(:qcm, chapter: chapter, online: true, position: 3, level: 3) }
  let!(:item_correct) { FactoryGirl.create(:item_correct, question: qcm, position: 1) }
  let!(:item_incorrect) { FactoryGirl.create(:item, question: qcm, position: 2) }
  let!(:qcm_multiple) { FactoryGirl.create(:qcm_multiple, chapter: chapter, online: true, position: 4, level: 4) }
  let!(:item_multiple_correct) { FactoryGirl.create(:item_correct, question: qcm_multiple, position: 1) }
  let!(:item_multiple_incorrect) { FactoryGirl.create(:item, question: qcm_multiple, position: 2) }
  
  describe "user" do
    let!(:rating_before) { user.rating }
    let!(:section_rating_before) { user.pointspersections.where(:section_id => section).first.points }
    before { sign_in user }
    
    describe "visits an integer exercise" do
      before { visit chapter_path(chapter, :type => 5, :which => exercise) }
    
      describe "and correctly solves it" do
        before do
          fill_in "solvedquestion[guess]", with: exercise.answer
          click_button "Soumettre"
          user.reload
        end
        specify do
          expect(page).to have_content("Vous avez résolu cet exercice du premier coup !")
          expect(page).to have_content(exercise.explanation)
          expect(user.rating).to eq(rating_before + exercise.value)
          expect(user.pointspersections.where(:section_id => section).first.points).to eq(section_rating_before + exercise.value)
        end
      end
      
      describe "and makes a mistake" do
        before do
          fill_in "solvedquestion[guess]", with: exercise.answer + 1
          click_button "Soumettre"
          user.reload
        end
        specify do
          expect(page).to have_content("Votre réponse (#{(exercise.answer+1).to_i}) est erronée. Vous avez déjà commis 1 erreur.")
          expect(page).to have_no_content(exercise.explanation)
          expect(user.rating).to eq(rating_before)
          expect(user.pointspersections.where(:section_id => section).first.points).to eq(section_rating_before)
        end
        
        describe "and then solves it" do
          before do
            fill_in "solvedquestion[guess]", with: exercise.answer
            click_button "Soumettre"
            user.reload
          end
          specify do
            expect(page).to have_content("Vous avez résolu cet exercice après 1 erreur.")
            expect(page).to have_content(exercise.explanation)
            expect(user.rating).to eq(rating_before + exercise.value)
            expect(user.pointspersections.where(:section_id => section).first.points).to eq(section_rating_before + exercise.value)
          end
        end
        
        describe "and makes two other mistakes" do
          before do
            fill_in "solvedquestion[guess]", with: exercise.answer + 2
            click_button "Soumettre"
            fill_in "solvedquestion[guess]", with: exercise.answer + 3
            click_button "Soumettre"
          end
          it do
            should have_no_button("Soumettre") # Should be disabled
            should have_content("Vous devez encore patienter")
          end
          
          describe "and waits for 3 minutes" do
            let(:solvedquestion) { Solvedquestion.where(:user => user, :question => exercise).first }
            before do
              solvedquestion.updated_at = DateTime.now - 190
              solvedquestion.save
              visit chapter_path(chapter, :type => 5, :which => exercise)
            end
            it do
              should have_button("Soumettre")
              should have_no_content("Vous devez encore patienter")
            end
            
            describe "and makes a new guess" do
              before do
                fill_in "solvedquestion[guess]", with: exercise.answer
                click_button "Soumettre"
                user.reload
              end
              specify do 
                expect(page).to have_content("Vous avez résolu cet exercice après 3 erreurs.")
                expect(page).to have_content(exercise.explanation)
                expect(user.rating).to eq(rating_before + exercise.value)
                expect(user.pointspersections.where(:section_id => section).first.points).to eq(section_rating_before + exercise.value)
              end
            end
          end
        end
      end
    end
    
    describe "visits a decimal exercise" do
      before { visit chapter_path(chapter, :type => 5, :which => exercise_decimal) }
    
      describe "and correctly solves it" do
        before do
          fill_in "solvedquestion[guess]", with: exercise_decimal.answer + 0.0005
          click_button "Soumettre"
          user.reload
        end
        specify do
          expect(page).to have_content("Vous avez résolu cet exercice du premier coup !")
          expect(page).to have_content(exercise_decimal.explanation)
          expect(user.rating).to eq(rating_before + exercise_decimal.value)
          expect(user.pointspersections.where(:section_id => section).first.points).to eq(section_rating_before + exercise_decimal.value)
        end
      end
      
      describe "and makes a mistake (too large)" do
        before do
          fill_in "solvedquestion[guess]", with: exercise_decimal.answer + 0.002
          click_button "Soumettre"
          user.reload
        end
        specify do
          expect(page).to have_content("Votre réponse (#{(exercise_decimal.answer+0.002).to_s}) est erronée. Vous avez déjà commis 1 erreur.")
          expect(page).to have_no_content(exercise_decimal.explanation)
          expect(user.rating).to eq(rating_before)
          expect(user.pointspersections.where(:section_id => section).first.points).to eq(section_rating_before)
        end
      
        describe "and makes another mistake (too small)" do
          before do
            fill_in "solvedquestion[guess]", with: exercise_decimal.answer - 0.002
            click_button "Soumettre"
            user.reload
          end
          specify do
            expect(page).to have_content("Votre réponse (#{(exercise_decimal.answer-0.002).to_s}) est erronée. Vous avez déjà commis 2 erreurs.")
            expect(page).to have_no_content(exercise_decimal.explanation)
            expect(user.rating).to eq(rating_before)
            expect(user.pointspersections.where(:section_id => section).first.points).to eq(section_rating_before)
          end
        end
      end
    end
    
    describe "visits a single answer qcm" do
      before { visit chapter_path(chapter, :type => 5, :which => qcm) }
    
      describe "and correctly solves it" do
        before do
          choose "ans[#{item_correct.id}]"
          click_button "Soumettre"
          user.reload
        end
        specify do
          expect(page).to have_content("Vous avez résolu cet exercice du premier coup !")
          expect(page).to have_content(qcm.explanation)
          expect(user.rating).to eq(rating_before + qcm.value)
          expect(user.pointspersections.where(:section_id => section).first.points).to eq(section_rating_before + qcm.value)
        end
      end
      
      describe "and makes a mistake" do
        before do
          choose "ans[#{item_incorrect.id}]"
          click_button "Soumettre"
          user.reload
        end
        specify do
          expect(page).to have_content("Votre réponse est erronée. Vous avez déjà commis 1 erreur.")
          expect(page).to have_no_content(qcm.explanation)
          expect(user.rating).to eq(rating_before)
          expect(user.pointspersections.where(:section_id => section.id).first.points).to eq(section_rating_before)
        end
        
        describe "and makes the same mistake" do
          before do
            click_button "Soumettre"
            user.reload
          end
          it { should have_content("Votre réponse est erronée. Vous avez déjà commis 1 erreur.") }
        end
      end
      
      describe "and does not check any answer" do
        before do
          click_button "Soumettre"
          user.reload
        end
        it do
          should have_error_message("Veuillez cocher une réponse")
          should have_no_content("Votre réponse est erronée. Vous avez déjà commis 1 erreur.")
        end
      end
    end
    
    describe "visits a multiple answer qcm" do
      before { visit chapter_path(chapter, :type => 5, :which => qcm_multiple) }
    
      describe "and correctly solves it" do
        before do
          check "ans[#{item_multiple_correct.id}]"
          uncheck "ans[#{item_multiple_incorrect.id}]"
          click_button "Soumettre"
          user.reload
        end
        specify do
          expect(page).to have_content("Vous avez résolu cet exercice du premier coup !")
          expect(page).to have_content(qcm_multiple.explanation)
          expect(user.rating).to eq(rating_before + qcm_multiple.value)
          expect(user.pointspersections.where(:section_id => section).first.points).to eq(section_rating_before + qcm_multiple.value)
        end
      end
      
      describe "and makes a mistake" do
        before do
          check "ans[#{item_multiple_correct.id}]"
          check "ans[#{item_multiple_incorrect.id}]"
          click_button "Soumettre"
          user.reload
        end
        specify do
          expect(page).to have_content("Votre réponse est erronée. Vous avez déjà commis 1 erreur.")
          expect(page).to have_no_content(qcm_multiple.explanation)
          expect(user.rating).to eq(rating_before)
          expect(user.pointspersections.where(:section_id => section).first.points).to eq(section_rating_before)
        end
        
        describe "and makes another mistake" do
          before do
            uncheck "ans[#{item_multiple_correct.id}]"
            uncheck "ans[#{item_multiple_incorrect.id}]"
            click_button "Soumettre"
            user.reload
          end
          it { should have_content("Votre réponse est erronée. Vous avez déjà commis 2 erreurs.") }
          
          describe "and correctly solves it" do
            before do
              check "ans[#{item_multiple_correct.id}]"
              uncheck "ans[#{item_multiple_incorrect.id}]"
              click_button "Soumettre"
              user.reload
            end
            specify do
              expect(page).to have_content("Vous avez résolu cet exercice après 2 erreurs.")
              expect(page).to have_content(qcm_multiple.explanation)
              expect(user.rating).to eq(rating_before + qcm_multiple.value)
              expect(user.pointspersections.where(:section_id => section).first.points).to eq(section_rating_before + qcm_multiple.value)
            end
          end
        end
        
        describe "and makes the same mistake" do
          before do
            click_button "Soumettre"
            user.reload
          end
          it { should have_content("Votre réponse est erronée. Vous avez déjà commis 1 erreur.") }
        end
      end
      
      describe "and does not check any answer" do # There is a special line for this in the controller
        before do
          click_button "Soumettre"
          user.reload
        end
        it { should have_content("Votre réponse est erronée. Vous avez déjà commis 1 erreur.") }
      end
    end
  end
  
  describe "cron job" do
    let!(:yesterday) { Date.today.in_time_zone - 1.day + 10.hours }
    let!(:cheater) { FactoryGirl.create(:user) }
    let!(:sq1) { FactoryGirl.create(:solvedquestion, user: cheater, correct: true, resolution_time: yesterday) }
    let!(:sq2) { FactoryGirl.create(:solvedquestion, user: cheater, correct: true, resolution_time: yesterday + 15.seconds) }
    let!(:sq3) { FactoryGirl.create(:solvedquestion, user: cheater, correct: true, resolution_time: yesterday + 40.seconds) }
    let!(:sq4) { FactoryGirl.create(:solvedquestion, user: cheater, correct: true, resolution_time: yesterday + 45.seconds) }
    let!(:sq5) { FactoryGirl.create(:solvedquestion, user: cheater, correct: true, resolution_time: yesterday + 1.minute) }
    let!(:sq6) { FactoryGirl.create(:solvedquestion, user: cheater, correct: true, resolution_time: yesterday + 2.minutes + 4.seconds) }
    let!(:sq7) { FactoryGirl.create(:solvedquestion, user: cheater, correct: true, resolution_time: yesterday + 5.minutes) }
    let!(:sq8) { FactoryGirl.create(:solvedquestion, user: cheater, correct: true, resolution_time: yesterday + 5.minutes + 10.seconds) }
    let!(:sq9) { FactoryGirl.create(:solvedquestion, user: cheater, correct: true, resolution_time: yesterday + 11.minutes) }
    
    describe "searches for suspicious users for the first time" do
      before do
        Subject.where(:subject_type => :corrector_alerts).destroy_all
        Solvedquestion.detect_suspicious_users
      end
      specify do
        expect(Subject.where(:subject_type => :corrector_alerts).count).to eq(1)
        expect(Subject.last.user_id).to eq(0)
        expect(Subject.last.content).to include(cheater.name)
        expect(Subject.last.content).to include("a résolu 6 exercices en 3 minutes et 8 exercices en 10 minutes")
        expect(Subject.last.content).to include("Il a résolu 5 exercices après moins d'une minute de réflexion, dont un en 5 secondes")
        expect(Subject.last.messages.count).to eq(0) # No message for the moment
      end
      
      describe "and searches a second time" do
        before { Solvedquestion.detect_suspicious_users }
        specify do
          expect(Subject.where(:subject_type => :corrector_alerts).count).to eq(1)
          expect(Subject.last.messages.count).to eq(1)
          expect(Message.last.user_id).to eq (0)
          expect(Message.last.content).to include(cheater.name)
          expect(Message.last.content).to include("a résolu 6 exercices en 3 minutes et 8 exercices en 10 minutes")
          expect(Message.last.content).to include("Il a résolu 5 exercices après moins d'une minute de réflexion, dont un en 5 secondes")
        end
      end
    end
  end
end
