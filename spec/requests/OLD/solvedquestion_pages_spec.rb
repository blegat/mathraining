# -*- coding: utf-8 -*-
require "spec_helper"

describe "Solvedquestion pages", question: true do

  subject { page }

  let(:admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }
  let!(:section) { FactoryGirl.create(:section) }
  let!(:chapter) { FactoryGirl.create(:chapter, section: section, online: true) }
  let!(:chapter2) { FactoryGirl.create(:chapter, section: section, online: true) }
  let!(:exercise_answer) { 6321567 }
  let!(:exercise) { FactoryGirl.create(:exercise, chapter: chapter, online: true, position: 1, level: 1, answer: exercise_answer) }
  let!(:exercise_decimal_answer) { -15.4 }
  let!(:exercise_decimal) { FactoryGirl.create(:exercise_decimal, chapter: chapter, online: true, position: 2, level: 2, answer: exercise_decimal_answer) }
  let!(:qcm) { FactoryGirl.create(:qcm, chapter: chapter, online: true, position: 3, level: 3) }
  let!(:item_correct) { FactoryGirl.create(:item_correct, question: qcm, position: 1) }
  let!(:item_incorrect) { FactoryGirl.create(:item, question: qcm, position: 2) }
  let!(:qcm_multiple) { FactoryGirl.create(:qcm_multiple, chapter: chapter2, online: true, position: 4, level: 4) } # Only question of chapter2
  let!(:item_multiple_correct) { FactoryGirl.create(:item_correct, question: qcm_multiple, position: 1) }
  let!(:item_multiple_incorrect) { FactoryGirl.create(:item, question: qcm_multiple, position: 2) }
  
  describe "user", :js => true do
    let!(:rating_before) { user.rating }
    let!(:section_rating_before) { user.pointspersections.where(:section_id => section).first.points }
    before { sign_in user }
    
    describe "tries to see the answer to a question he solved" do
      let!(:solvedquestion) { FactoryGirl.create(:solvedquestion, user: user, question: exercise) }
      before do
        visit chapter_question_path(chapter, exercise)
        click_link "Voir la réponse"
      end
      specify do
        expect(page).to have_selector("h4", text: "Réponse")
        expect(page).to have_content(exercise_answer)
        expect(page).to have_selector("h4", text: "Explication")
        expect(page).to have_content(exercise.explanation)
      end
    end
    
    describe "tries to see the answer to a question he did NOT solve (hack)" do
      let!(:solvedquestion) { FactoryGirl.create(:solvedquestion, user: user, question: exercise) } # To have the link 'Voir la réponse'
      before do
        visit chapter_question_path(chapter, exercise)
        solvedquestion.destroy
        click_link "Voir la réponse"
      end
      specify do
        expect(page).to have_no_selector("h4", text: "Réponse")
        expect(page).to have_no_content(exercise_answer)
        expect(page).to have_no_selector("h4", text: "Explication")
        expect(page).to have_no_content(exercise.explanation)
      end
    end
    
    describe "visits an integer exercise" do
      before { visit chapter_question_path(chapter, exercise) }
    
      describe "and correctly solves it" do
        before do
          fill_in "ans", with: exercise_answer
          click_button "Soumettre"
          user.reload
        end
        specify do
          expect(page).to have_success_message("Bonne réponse !")
          expect(page).to have_content("du premier coup !")
          expect(page).to have_content(exercise.explanation)
          expect(page).to have_selector("span", class: "bg-success", text: "#{exercise.value} points")
          expect(page).to have_selector("a", id: "menu-question-#{exercise.id}", class: "list-group-item-success")
          expect(user.rating).to eq(rating_before + exercise.value)
          expect(user.pointspersections.where(:section_id => section).first.points).to eq(section_rating_before + exercise.value)
        end
      end
      
      describe "and writes a decimal number" do
        before do
          fill_in "ans", with: "4.6"
          click_button "Soumettre"
          user.reload
        end
        specify do
          expect(page).to have_info_message("La réponse attendue est un nombre entier.")
          expect(page).to have_no_selector("span", class: "bg-success", text: "#{exercise.value} points")
          expect(page).to have_no_selector("a", id: "menu-question-#{exercise.id}", class: "list-group-item-success")
          expect(page).to have_no_selector("a", id: "menu-question-#{exercise.id}", class: "list-group-item-danger")
          expect(page).to have_no_content(exercise.explanation)
          expect(page).to have_no_content("Vous avez déjà commis") # Should not be counted as an error
          expect(user.rating).to eq(rating_before)
        end
      end
      
      describe "and makes a mistake" do
        before do
          fill_in "ans", with: exercise_answer + 1
          click_button "Soumettre"
          user.reload
        end
        specify do
          expect(page).to have_error_message("Mauvaise réponse...")
          expect(page).to have_content("Votre réponse (#{exercise_answer+1}) est erronée. Vous avez déjà commis 1 erreur.")
          expect(page).to have_no_content(exercise.explanation)
          expect(page).to have_no_selector("span", class: "bg-success", text: "#{exercise.value} points")
          expect(page).to have_selector("a", id: "menu-question-#{exercise.id}", class: "list-group-item-danger")
          expect(user.rating).to eq(rating_before)
          expect(user.pointspersections.where(:section_id => section).first.points).to eq(section_rating_before)
        end
        
        describe "and then solves it" do
          before do
            fill_in "ans", with: exercise_answer
            click_button "Soumettre"
            user.reload
          end
          specify do
            expect(page).to have_success_message("Bonne réponse !")
            expect(page).to have_content("après 1 erreur.")
            expect(page).to have_content(exercise.explanation)
            expect(page).to have_no_selector("a", id: "menu-question-#{exercise.id}", class: "list-group-item-danger")
            expect(page).to have_selector("a", id: "menu-question-#{exercise.id}", class: "list-group-item-success")
            expect(user.rating).to eq(rating_before + exercise.value)
            expect(user.pointspersections.where(:section_id => section).first.points).to eq(section_rating_before + exercise.value)
          end
        end
        
        describe "and makes the same mistake" do
          before do
            click_button "Soumettre"
            user.reload
          end
          specify do
            expect(page).to have_info_message("Cette réponse est la même")
            expect(page).to have_content("Vous avez déjà commis 1 erreur.")
            expect(user.rating).to eq(rating_before)
          end
        end
        
        describe "and makes two other mistakes" do
          before do
            fill_in "ans", with: exercise_answer + 2
            click_button "Soumettre"
            fill_in "ans", with: exercise_answer + 3
            click_button "Soumettre"
          end
          it do
            should have_button("Soumettre", disabled: true)
            should have_content("Vous devez encore patienter")
          end
        end
      end
    end
    
    describe "visits a question after 3 errors but 2 minutes", :js => false do
      let!(:unsolvedquestion) { FactoryGirl.create(:unsolvedquestion, user: user, question: exercise, nb_guess: 3, last_guess_time: DateTime.now - 2.minutes, guess: exercise_answer + 3) }
      before { visit chapter_question_path(chapter, exercise) }
      it do
        should have_button("Soumettre", disabled: true)
        should have_content("Vous devez encore patienter")
      end
    end
    
    describe "visits a question after 3 errors but 4 minutes", :js => false do
      let!(:unsolvedquestion) { FactoryGirl.create(:unsolvedquestion, user: user, question: exercise, nb_guess: 3, last_guess_time: DateTime.now - 4.minutes, guess: exercise_answer + 3) }
      before { visit chapter_question_path(chapter, exercise) }
      it do
        should have_button("Soumettre", disabled: false)
        should have_no_content("Vous devez encore patienter")
      end
      
      describe "and makes a 4th mistake", :js => true do
        before do
          fill_in "ans", with: exercise_answer + 12
          click_button "Soumettre"
        end
        it do
          should have_error_message("Mauvaise réponse...")
          should have_content("Votre réponse (#{exercise_answer+12}) est erronée. Vous avez déjà commis 4 erreurs.")
          should have_button("Soumettre", disabled: true)
          should have_content("Vous devez encore patienter")
        end
      end
    end
      
    describe "visits a question and tries to send an answer too early" do
      before do
        visit chapter_question_path(chapter, exercise)
        FactoryGirl.create(:unsolvedquestion, user: user, question: exercise, nb_guess: 3, last_guess_time: DateTime.now - 2.minutes, guess: exercise_answer + 3)
        fill_in "ans", with: exercise_answer
        click_button "Soumettre"
      end
      it { should have_info_message("Merci d'attendre") }
    end
    
    describe "visits a single answer qcm" do
      before { visit chapter_question_path(chapter, qcm) }
    
      describe "and correctly solves it" do
        before do
          choose "ans_#{item_correct.id}"
          click_button "Soumettre"
          user.reload
        end
        specify do
          expect(page).to have_success_message("Bonne réponse !")
          expect(page).to have_content("du premier coup !")
          expect(page).to have_content(qcm.explanation)
          expect(user.rating).to eq(rating_before + qcm.value)
          expect(user.pointspersections.where(:section_id => section).first.points).to eq(section_rating_before + qcm.value)
          expect(user.chapters.exists?(chapter.id)).to eq(false) # Because it's NOT the only question of chapter
        end
            
        describe "and correctly solves it again for fun" do
          before do
            visit chapter_question_path(chapter, qcm)
            choose "ans_#{item_correct.id}"
            click_button "Soumettre"
            user.reload
          end
          
          specify do
            expect(page).to have_success_message("Bonne réponse !")
            expect(page).to have_content("du premier coup !")
            expect(page).to have_content(qcm.explanation)
            expect(user.solvedquestions.where(:question => qcm).count).to eq(1) # And not 2
            expect(user.rating).to eq(rating_before + qcm.value) # Should not gain points again!
            expect(user.pointspersections.where(:section_id => section).first.points).to eq(section_rating_before + qcm.value) # Should not gain points again!
          end
        end
        
        describe "and makes a mistake for fun" do
          before do
            visit chapter_question_path(chapter, qcm)
            choose "ans_#{item_incorrect.id}"
            click_button "Soumettre"
            user.reload
          end
          
          specify do
            expect(page).to have_error_message("Mauvaise réponse...")
            expect(page).to have_no_content(exercise.explanation)
            expect(page).to have_selector("a", id: "menu-question-#{qcm.id}", class: "list-group-item-success") # should still be green
            expect(user.unsolvedquestions.where(:question => qcm).count).to eq(0) # When answering for fun, no unsolvedquestion should be created!
          end
        end
      end
      
      describe "and makes a mistake" do
        before do
          choose "ans_#{item_incorrect.id}"
          click_button "Soumettre"
          user.reload
        end
        specify do
          expect(page).to have_error_message("Mauvaise réponse...")
          expect(page).to have_content("Votre réponse est erronée. Vous avez déjà commis 1 erreur.")
          expect(page).to have_no_content(qcm.explanation)
          expect(user.rating).to eq(rating_before)
          expect(user.pointspersections.where(:section_id => section.id).first.points).to eq(section_rating_before)
        end
      end
      
      describe "and does not check any answer" do
        before do
          click_button "Soumettre"
          user.reload
        end
        specify do
          expect(page).to have_info_message("Veuillez cocher une réponse.")
          expect(page).to have_no_content("Votre réponse est erronée. Vous avez déjà commis 1 erreur.")
          expect(user.rating).to eq(rating_before)
        end
      end
    end
    
    describe "visits a multiple answer qcm" do
      before { visit chapter_question_path(chapter2, qcm_multiple) }
    
      describe "and correctly solves it" do
        before do
          check "ans_#{item_multiple_correct.id}"
          uncheck "ans_#{item_multiple_incorrect.id}"
          click_button "Soumettre"
          user.reload
        end
        specify do
          expect(page).to have_success_message("Bonne réponse !")
          expect(page).to have_content("du premier coup !")
          expect(page).to have_content(qcm_multiple.explanation)
          expect(user.rating).to eq(rating_before + qcm_multiple.value)
          expect(user.pointspersections.where(:section_id => section).first.points).to eq(section_rating_before + qcm_multiple.value)
          expect(user.chapters.exists?(chapter2.id)).to eq(true) # Because it's the only question of chapter2
        end
      end
      
      describe "and makes a mistake" do
        before do
          check "ans_#{item_multiple_correct.id}"
          check "ans_#{item_multiple_incorrect.id}"
          click_button "Soumettre"
          user.reload
        end
        specify do
          expect(page).to have_error_message("Mauvaise réponse...")
          expect(page).to have_content("Votre réponse est erronée. Vous avez déjà commis 1 erreur.")
          expect(page).to have_no_content(qcm_multiple.explanation)
          expect(user.rating).to eq(rating_before)
          expect(user.pointspersections.where(:section_id => section).first.points).to eq(section_rating_before)
          expect(user.chapters.exists?(chapter2.id)).to eq(false)
        end
      end
    end
  end
  
  describe "admin", :js => true do
    before { sign_in admin }
    
    describe "visits a decimal exercise" do
      before { visit chapter_question_path(chapter, exercise_decimal) }
    
      describe "and correctly solves it for fun" do
        before do
          fill_in "ans", with: exercise_decimal_answer - 0.0005
          click_button "Soumettre"
          admin.reload
        end
        specify do
          expect(page).to have_success_message("Bonne réponse !")
          expect(page).to have_no_content("du premier coup !") # Only for students
          expect(page).to have_content(exercise_decimal.explanation)
          expect(page).to have_no_selector("a", id: "menu-question-#{exercise_decimal.id}", class: "list-group-item-success") # Should not become green
          expect(admin.solvedquestions.where(:question => exercise_decimal).count).to eq(0) # Should not be created for an admin
          expect(admin.rating).to eq(0)
          expect(admin.pointspersections.where(:section_id => section).first.points).to eq(0)
        end
      end
      
      describe "and makes a mistake for fun" do
        before do
          fill_in "ans", with: exercise_decimal_answer - 0.6
          click_button "Soumettre"
          admin.reload
        end
        specify do
          expect(page).to have_error_message("Mauvaise réponse...")
          expect(page).to have_no_content(exercise_decimal.explanation)
          expect(page).to have_no_selector("a", id: "menu-question-#{exercise_decimal.id}", class: "list-group-item-danger") # Should not become red
          expect(admin.unsolvedquestions.where(:question => exercise_decimal).count).to eq(0) # Should not be created for an admin
        end
      end
      
      describe "and clicks to see the answer" do
        before do
          click_link "Voir la réponse"
        end
        specify do
          expect(page).to have_selector("h4", text: "Réponse")
          expect(page).to have_content(exercise_decimal_answer)
          expect(page).to have_selector("h4", text: "Explication")
          expect(page).to have_content(exercise_decimal.explanation)
        end
      end
    end
    
    describe "visits a single answer qcm" do
      before { visit chapter_question_path(chapter, qcm) }
      
      describe "and does not check any option for fun" do
        before do
          click_button "Soumettre"
        end
        specify do
          expect(page).to have_info_message("Veuillez cocher une réponse.")
          expect(page).not_to have_content(qcm.explanation)
          expect(page).to have_no_selector("a", id: "menu-question-#{qcm.id}", class: "list-group-item-success") # Should not become green
          expect(page).to have_no_selector("a", id: "menu-question-#{qcm.id}", class: "list-group-item-danger") # Should not become red
        end
      end
    end
    
    describe "visits a multiple answer qcm" do
      before { visit chapter_question_path(chapter2, qcm_multiple) }
    
      describe "and correctly solves it for fun" do
        before do
          check "ans_#{item_multiple_correct.id}"
          uncheck "ans_#{item_multiple_incorrect.id}"
          click_button "Soumettre"
          admin.reload
        end
        specify do
          expect(page).to have_success_message("Bonne réponse !")
          expect(page).to have_no_content("du premier coup !") # Only for students
          expect(page).to have_content(qcm_multiple.explanation)
          expect(admin.solvedquestions.where(:question => qcm_multiple).count).to eq(0) # Should not be created for an admin
          expect(admin.rating).to eq(0)
          expect(admin.pointspersections.where(:section_id => section).first.points).to eq(0)
          expect(admin.chapters.exists?(chapter2.id)).to eq(false) # Even if it's the only question of chapter2
        end
      end
    end
  end
  
  describe "cron job" do
    let!(:yesterday) { Date.today.in_time_zone - 1.day + 10.hours }
    let!(:cheater) { FactoryGirl.create(:user) }
    let!(:sq1)  { FactoryGirl.create(:solvedquestion, user: cheater, resolution_time: yesterday) }
    let!(:sq2)  { FactoryGirl.create(:solvedquestion, user: cheater, resolution_time: yesterday + 15.seconds) }
    let!(:sq3)  { FactoryGirl.create(:solvedquestion, user: cheater, resolution_time: yesterday + 40.seconds) }
    let!(:sq4)  { FactoryGirl.create(:solvedquestion, user: cheater, resolution_time: yesterday + 45.seconds) }
    let!(:sq5)  { FactoryGirl.create(:solvedquestion, user: cheater, resolution_time: yesterday + 1.minute) }
    let!(:sq6)  { FactoryGirl.create(:solvedquestion, user: cheater, resolution_time: yesterday + 2.minutes + 4.seconds) }
    let!(:sq7)  { FactoryGirl.create(:solvedquestion, user: cheater, resolution_time: yesterday + 5.minutes) }
    let!(:sq8)  { FactoryGirl.create(:solvedquestion, user: cheater, resolution_time: yesterday + 5.minutes + 10.seconds) }
    let!(:sq9)  { FactoryGirl.create(:solvedquestion, user: cheater, resolution_time: yesterday + 11.minutes) }
    let!(:sq10) { FactoryGirl.create(:solvedquestion, user: cheater, resolution_time: yesterday + 11.minutes + 40.seconds) }
    let!(:sq11) { FactoryGirl.create(:solvedquestion, user: cheater, resolution_time: yesterday + 12.minutes + 20.seconds) }
    let!(:sq12) { FactoryGirl.create(:solvedquestion, user: cheater, resolution_time: yesterday + 12.minutes + 30.seconds) }
    let!(:sq13) { FactoryGirl.create(:solvedquestion, user: cheater, resolution_time: yesterday + 12.minutes + 40.seconds) }
    let!(:sq14) { FactoryGirl.create(:solvedquestion, user: cheater, resolution_time: yesterday + 12.minutes + 50.seconds) }
    
    describe "searches for suspicious users for the first time" do
      before do
        Subject.where(:subject_type => :corrector_alerts).destroy_all
        Solvedquestion.detect_suspicious_users
      end
      specify do
        expect(Subject.where(:subject_type => :corrector_alerts).count).to eq(1)
        expect(Subject.last.messages.count).to eq(1)
        expect(Subject.last.messages.last.user_id).to eq(0)
        expect(Subject.last.messages.last.content).to include(cheater.name)
        expect(Subject.last.messages.last.content).to include("a résolu 6 exercices en 3 minutes et 8 exercices en 10 minutes")
        expect(Subject.last.messages.last.content).to include("Il a résolu 10 exercices après moins d'une minute de réflexion, dont un en 5 secondes")
      end
      
      describe "and searches a second time" do
        before { Solvedquestion.detect_suspicious_users }
        specify do
          expect(Subject.where(:subject_type => :corrector_alerts).count).to eq(1)
          expect(Subject.last.messages.count).to eq(2)
          expect(Message.last.user_id).to eq (0)
          expect(Message.last.content).to include(cheater.name)
          expect(Message.last.content).to include("a résolu 6 exercices en 3 minutes et 8 exercices en 10 minutes")
          expect(Message.last.content).to include("Il a résolu 10 exercices après moins d'une minute de réflexion, dont un en 5 secondes")
        end
      end
    end
  end
end
