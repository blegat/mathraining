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
        it do
          should have_content("Vous avez résolu cet exercice du premier coup !")
          should have_content(exercise.explanation)
        end
        specify do
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
        it do
          should have_content("Votre réponse (#{(exercise.answer+1).to_i}) est erronée. Vous avez déjà commis 1 erreur.")
          should have_no_content(exercise.explanation)
        end
        specify do
          expect(user.rating).to eq(rating_before)
          expect(user.pointspersections.where(:section_id => section).first.points).to eq(section_rating_before)
        end
        
        describe "and then solves it" do
          before do
            fill_in "solvedquestion[guess]", with: exercise.answer
            click_button "Soumettre"
            user.reload
          end
          it do
            should have_content("Vous avez résolu cet exercice après 1 erreur.")
            should have_content(exercise.explanation)
          end
          specify do
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
              it do 
                should have_content("Vous avez résolu cet exercice après 3 erreurs.")
                should have_content(exercise.explanation)
              end
              specify do
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
        it do
          should have_content("Vous avez résolu cet exercice du premier coup !")
          should have_content(exercise_decimal.explanation)
        end
        specify do
          expect(user.rating).to eq(rating_before + exercise_decimal.value)
          expect(user.pointspersections.where(:section_id => section).first.points).to eq(section_rating_before + exercise_decimal.value)
        end
      end
      
      describe "and makes a mistake" do
        before do
          fill_in "solvedquestion[guess]", with: exercise_decimal.answer + 0.002
          click_button "Soumettre"
          user.reload
        end
        it do
          should have_content("Votre réponse (#{(exercise_decimal.answer+0.002).to_s}) est erronée. Vous avez déjà commis 1 erreur.")
          should have_no_content(exercise_decimal.explanation)
        end
        specify do
          expect(user.rating).to eq(rating_before)
          expect(user.pointspersections.where(:section_id => section).first.points).to eq(section_rating_before)
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
        it do
          should have_content("Vous avez résolu cet exercice du premier coup !")
          should have_content(qcm.explanation)
        end
        specify do
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
        it do
          should have_content("Votre réponse est erronée. Vous avez déjà commis 1 erreur.")
          should have_no_content(qcm.explanation)
        end
        specify do
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
          should have_content("Veuillez cocher une réponse")
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
        it do
          should have_content("Vous avez résolu cet exercice du premier coup !")
          should have_content(qcm_multiple.explanation)
        end
        specify do
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
        it do
          should have_content("Votre réponse est erronée. Vous avez déjà commis 1 erreur.")
          should have_no_content(qcm_multiple.explanation)
        end
        specify do
          expect(user.rating).to eq(rating_before)
          expect(user.pointspersections.where(:section_id => section).first.points).to eq(section_rating_before)
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
end
