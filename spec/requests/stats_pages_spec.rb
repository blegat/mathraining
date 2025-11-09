# -*- coding: utf-8 -*-
require "spec_helper"

describe "Stats pages" do

  subject { page }

  let(:user1) { FactoryBot.create(:user) }
  let(:user2) { FactoryBot.create(:user) }
  let(:user3) { FactoryBot.create(:user) }
  let(:admin) { FactoryBot.create(:admin) }
  
  let!(:section) { FactoryBot.create(:section) }
  
  let!(:chapter1) { FactoryBot.create(:chapter, section: section, online: true) }
  let!(:chapter2) { FactoryBot.create(:chapter, section: section, online: true) }
  
  let!(:exercise11) { FactoryBot.create(:exercise_decimal, chapter: chapter1, online: true, position: 1, level: 1) }
  let!(:exercise12) { FactoryBot.create(:exercise_decimal, chapter: chapter1, online: true, position: 2, level: 2) }
  let!(:exercise13_offline) { FactoryBot.create(:exercise_decimal, chapter: chapter1, online: false, position: 3, level: 3) }
  let!(:exercise21) { FactoryBot.create(:exercise_decimal, chapter: chapter2, online: true, position: 1, level: 1) }
  let!(:exercise22) { FactoryBot.create(:exercise_decimal, chapter: chapter2, online: true, position: 2, level: 2) }
  
  describe "user" do
    before { sign_in user1 }
    
    describe "tries the first exercise of a chapter", :js => true do
      before do
        exercise11.update(:nb_wrong => 0, :nb_correct => 0, :nb_first_guesses => 0)
        chapter1.update(:nb_tries => 0, :nb_completions => 0)
        visit chapter_question_path(chapter1, exercise11)
        fill_in "ans", with: exercise11.answer + 12
        click_button "Soumettre"
        wait_for_ajax
        chapter1.reload
        exercise11.reload
      end
      specify do
        expect(chapter1.nb_tries).to eq(1)
        expect(chapter1.nb_completions).to eq(0)
        expect(exercise11.nb_wrong).to eq(1)
        expect(exercise11.nb_correct).to eq(0)
        expect(exercise11.nb_first_guesses).to eq(0)
      end
      
      describe "and then solves it correctly" do
        before do
          visit chapter_question_path(chapter1, exercise11)
          fill_in "ans", with: exercise11.answer
          click_button "Soumettre"
          wait_for_ajax
          chapter1.reload
          exercise11.reload
        end
        specify do
          expect(chapter1.nb_tries).to eq(1)
          expect(chapter1.nb_completions).to eq(0)
          expect(exercise11.nb_wrong).to eq(0)
          expect(exercise11.nb_correct).to eq(1)
          expect(exercise11.nb_first_guesses).to eq(0)
        end
      end
    end
    
    describe "solves the first exercise of a chapter", :js => true do
      before do
        exercise11.update(:nb_wrong => 0, :nb_correct => 0, :nb_first_guesses => 0)
        exercise12.update(:nb_wrong => 0, :nb_correct => 0, :nb_first_guesses => 0)
        chapter1.update(:nb_tries => 0, :nb_completions => 0)
        chapter2.update(:nb_tries => 0, :nb_completions => 0)
        visit chapter_question_path(chapter1, exercise11)
        fill_in "ans", with: exercise11.answer
        click_button "Soumettre"
        wait_for_ajax
        chapter1.reload
        exercise11.reload
      end
      specify do
        expect(chapter1.nb_tries).to eq(1)
        expect(chapter1.nb_completions).to eq(0)
        expect(exercise11.nb_wrong).to eq(0)
        expect(exercise11.nb_correct).to eq(1)
        expect(exercise11.nb_first_guesses).to eq(1)
      end
      
      describe "and solves the second exercise of the chapter" do
        before do
          visit chapter_question_path(chapter1, exercise12)
          fill_in "ans", with: exercise12.answer
          click_button "Soumettre"
          wait_for_ajax
          chapter1.reload
          exercise12.reload
        end
        specify do
          expect(chapter1.nb_tries).to eq(1)
          expect(chapter1.nb_completions).to eq(1)
          expect(exercise12.nb_wrong).to eq(0)
          expect(exercise12.nb_correct).to eq(1)
          expect(exercise12.nb_first_guesses).to eq(1)
        end
        
        describe "and recomputes the chapter stats" do
          before do
            # Change nb_tries and nb_completions in a wrong way
            chapter1.update(:nb_tries => 42,
                            :nb_completions => 42)
            chapter2.update(:nb_tries => 42,
                            :nb_completions => 42)
            Chapter.update_stats
            chapter1.reload
            chapter2.reload
          end
          specify do
            expect(chapter1.nb_tries).to eq(1)
            expect(chapter1.nb_completions).to eq(1)
            expect(chapter2.nb_tries).to eq(0)
            expect(chapter2.nb_completions).to eq(0)
          end
        end
        
        describe "and recomputes the question stats" do
          before do
            # Change nb_wrong, nb_correct and nb_first_guesses in a wrong way
            exercise11.update(:nb_wrong => 42,
                              :nb_correct => 42,
                              :nb_first_guesses => 42)
            exercise12.update(:nb_wrong => 42,
                              :nb_correct => 42,
                              :nb_first_guesses => 42)
            exercise21.update(:nb_wrong => 42,
                              :nb_correct => 42,
                              :nb_first_guesses => 42)
            Question.update_stats
            exercise11.reload
            exercise12.reload
            exercise21.reload
          end
          specify do
            expect(exercise11.nb_wrong).to eq(0)
            expect(exercise11.nb_correct).to eq(1)
            expect(exercise11.nb_first_guesses).to eq(1)
            expect(exercise12.nb_wrong).to eq(0)
            expect(exercise12.nb_correct).to eq(1)
            expect(exercise12.nb_first_guesses).to eq(1)
            expect(exercise12.nb_wrong).to eq(0)
            expect(exercise21.nb_correct).to eq(0)
            expect(exercise21.nb_first_guesses).to eq(0)
          end
        end
      end
    end
  end
  
  describe "admin" do
    before { sign_in admin }
    let!(:now) { DateTime.now }
    let!(:problem) { FactoryBot.create(:problem, section: section, online: true) }
    let!(:problem2) { FactoryBot.create(:problem, section: section, online: true) }
    let!(:submission1) { FactoryBot.create(:submission, problem: problem, user: user1, created_at: now - 7.days) }
    let!(:submission2) { FactoryBot.create(:submission, problem: problem, user: user2, created_at: now - 4.days) }
    let!(:submission3) { FactoryBot.create(:submission, problem: problem, user: user3, created_at: now - 2.days) }
    
    describe "marks a solution as correct" do
      before do
        Following.create(:user => admin, :submission => submission1, :read => true, :kind => :reservation)
        visit problem_path(problem, :sub => submission1)
        fill_in "MathInput", with: "C'est correct"
        click_button "Poster et accepter la soumission"
        problem.reload
      end
      specify do
        expect(problem.nb_solves).to eq(1)
        expect(problem.first_solve_time).to be_within(1.second).of(now - 7.days)
        expect(problem.last_solve_time).to be_within(1.second).of(now - 7.days)
      end
      
      describe "and marks a second solution as wrong" do
        before do
          Following.create(:user => admin, :submission => submission2, :read => true, :kind => :reservation)
          visit problem_path(problem, :sub => submission2)
          fill_in "MathInput", with: "C'est incorrect"
          click_button "Poster et refuser la soumission"
          problem.reload
        end
        specify do
          expect(problem.nb_solves).to eq(1)
          expect(problem.first_solve_time).to be_within(1.second).of(now - 7.days)
          expect(problem.last_solve_time).to be_within(1.second).of(now - 7.days)
        end
        
        describe "and marks a third solution as correct" do
          before do
            Following.create(:user => admin, :submission => submission3, :read => true, :kind => :reservation)
            visit problem_path(problem, :sub => submission3)
            fill_in "MathInput", with: "C'est correct"
            click_button "Poster et accepter la soumission"
            problem.reload
          end
          specify do
            expect(problem.nb_solves).to eq(2)
            expect(problem.first_solve_time).to be_within(1.second).of(now - 7.days)
            expect(problem.last_solve_time).to be_within(1.second).of(now - 2.days)
          end
          
          describe "and recomputes the problem stats" do
            before do
              # Change nb_solves, first_solve_time and last_solve_time in a wrong way
              problem.update(:nb_solves => 42,
                             :first_solve_time => now,
                             :last_solve_time => now)
              problem2.update(:nb_solves => 42,
                              :first_solve_time => now,
                              :last_solve_time => now)
              Problem.update_stats
              problem.reload
              problem2.reload
            end
            specify do
              expect(problem.nb_solves).to eq(2)
              expect(problem.first_solve_time).to be_within(1.second).of(now - 7.days)
              expect(problem.last_solve_time).to be_within(1.second).of(now - 2.days)
              expect(problem2.nb_solves).to eq(0)
              expect(problem2.first_solve_time).to eq(nil)
              expect(problem2.last_solve_time).to eq(nil)
            end
          end
        end
      end
    end
  end
  
  describe "cron job" do
  
    describe "computes solvedquestion stats" do
      let!(:now) { Time.zone.local(2015, 1, 14, 5, 0, 0) } # Wednesday 14/01/2015 at 5 am
      let!(:today) { now.in_time_zone.to_date }
      let!(:mondaybeforelastmonday) { today - 9 } # 05/01/2015
      let!(:solvedq11) { FactoryBot.create(:solvedquestion, user: user1, question: exercise11, resolution_time: now-28.days) }
      let!(:solvedq12) { FactoryBot.create(:solvedquestion, user: user1, question: exercise12, resolution_time: now-28.days) }
      let!(:solvedq21) { FactoryBot.create(:unsolvedquestion, user: user1, question: exercise21, guess: exercise21.answer + 1, last_guess_time: now-21.days) }
      let!(:solvedq22) { FactoryBot.create(:solvedquestion, user: user1, question: exercise22, resolution_time: now-14.days) }
      
      before do
        travel_to now
        Record.update
        travel_back
      end
      
      let!(:record0) { Record.where(:date => mondaybeforelastmonday - 35).first } # 01/12/2014 -> should not exist
      let!(:record1) { Record.where(:date => mondaybeforelastmonday - 28).first } # 08/12/2014
      let!(:record2) { Record.where(:date => mondaybeforelastmonday - 21).first } # 15/12/2014
      let!(:record3) { Record.where(:date => mondaybeforelastmonday - 14).first } # 22/12/2014
      let!(:record4) { Record.where(:date => mondaybeforelastmonday - 7).first }  # 29/12/2014
      let!(:record5) { Record.where(:date => mondaybeforelastmonday).first }      # 05/01/2015
      
      specify do
        expect(Record.count).to eq(5)
        
        expect(record0).to eq(nil)
        expect(record1.nb_questions_solved).to eq(0)
        expect(record2.nb_questions_solved).to eq(2)
        expect(record3.nb_questions_solved).to eq(0)
        expect(record4.nb_questions_solved).to eq(1)
        expect(record5.nb_questions_solved).to eq(0)
      end
    end
    
    describe "computes submission stats" do
      let!(:now) { Time.zone.local(2015, 1, 21, 5, 0, 0) } # Wednesday 21/01/2015 at 5 am
      let!(:today) { now.in_time_zone.to_date }
      let!(:mondaybeforelastmonday) { today - 9 } # 12/01/2015
      let!(:problem1) { FactoryBot.create(:problem, section: section, online: true, number: 1111, level: 1) }
      let!(:problem2) { FactoryBot.create(:problem, section: section, online: true, number: 1112, level: 2) }
      let!(:problem3) { FactoryBot.create(:problem, section: section, online: true, number: 1113, level: 3) }
      let!(:sub11) { FactoryBot.create(:submission, user: user1, problem: problem1, status: :correct, created_at: now-35.days) } # 17/12
      let!(:cor11) { FactoryBot.create(:correction, user: admin, submission: sub11, created_at: now-33.days) } # 2 days later
      let!(:sub12) { FactoryBot.create(:submission, user: user1, problem: problem2, status: :correct, created_at: now-28.days) } # 24/12
      let!(:cor12) { FactoryBot.create(:correction, user: admin, submission: sub12, created_at: now-27.days) } # 1 day later
      let!(:sub13) { FactoryBot.create(:submission, user: user1, problem: problem3, status: :wrong, created_at: now-28.days) } # 24/12
      let!(:cor13) { FactoryBot.create(:correction, user: admin, submission: sub13, created_at: now-26.days) } # 2 days later
      let!(:sub21) { FactoryBot.create(:submission, user: user2, problem: problem1, status: :wrong_to_read, created_at: now-28.days) } # 24/12
      let!(:cor21) { FactoryBot.create(:correction, user: admin, submission: sub21, created_at: now-24.days) } # 4 days later
      let!(:sub22) { FactoryBot.create(:submission, user: user2, problem: problem2, status: :waiting, created_at: now-21.days) } # 31/12
      let!(:sub23) { FactoryBot.create(:submission, user: user2, problem: problem3, status: :draft, created_at: now-21.days) }
      
      let!(:virtualtest) { FactoryBot.create(:virtualtest, online: true, duration: 2880) } # Test taking 2 days
      let!(:problem4_in_test) { FactoryBot.create(:problem, section: section, online: true, number: 1114, level: 4, virtualtest: virtualtest) }
      let!(:takentest) { Takentest.create(user: user1, virtualtest: virtualtest, taken_time: now-17.days, status: :in_progress) } # 04/01
      let!(:sub14) { FactoryBot.create(:submission, user: user1, problem: problem4_in_test, status: :waiting, intest: true, created_at: takentest.taken_time + virtualtest.duration.minutes)} # 04/01 + 2 days = 06/01
      
      before do
        travel_to now
        Record.update
        travel_back
      end
      
      let!(:record0) { Record.where(:date => mondaybeforelastmonday - 42).first } # 01/12/2014 -> should not exist
      let!(:record1) { Record.where(:date => mondaybeforelastmonday - 35).first } # 08/12/2014
      let!(:record2) { Record.where(:date => mondaybeforelastmonday - 28).first } # 15/12/2014
      let!(:record3) { Record.where(:date => mondaybeforelastmonday - 21).first } # 22/12/2014
      let!(:record4) { Record.where(:date => mondaybeforelastmonday - 14).first } # 29/12/2014
      let!(:record5) { Record.where(:date => mondaybeforelastmonday - 7).first }  # 05/01/2015
      let!(:record6) { Record.where(:date => mondaybeforelastmonday).first }      # 12/01/2015
      
      specify do
        expect(Record.count).to eq(6)
        
        expect(record0).to eq(nil)
        
        expect(record1.nb_submissions).to eq(0)
        expect(record1.complete).to eq(true)
        expect(record1.avg_correction_time).to eq(0.0)
        
        expect(record2.nb_submissions).to eq(1)
        expect(record2.complete).to eq(true)
        expect(record2.avg_correction_time).to eq(2.0)
        
        expect(record3.nb_submissions).to eq(3)
        expect(record3.complete).to eq(true)
        expect(record3.avg_correction_time.round(3)).to eq((7.0/3.0).round(3))
        
        expect(record4.nb_submissions).to eq(1)
        expect(record4.complete).to eq(false)
        
        expect(record5.nb_submissions).to eq(1)
        expect(record5.complete).to eq(false)
        
        expect(record6.nb_submissions).to eq(0)
        expect(record6.complete).to eq(true)
        expect(record6.avg_correction_time).to eq(0.0)
      end
      
      describe "and recomputes submission stats a week later" do
        let!(:cor22) { FactoryBot.create(:correction, user: admin, submission: sub22, created_at: now+2.days+6.hours) } # 23.25 days later
        let!(:cor14) { FactoryBot.create(:correction, user: admin, submission: sub14, created_at: now+1.day+12.hours) } # 16.5 days after end of test
        before do
          sub22.wrong_to_read!
          sub23.waiting!
          sub23.update_attribute(:created_at, now+2.days) # Draft was sent but not corrected
          sub14.correct!
          travel_to now+7.days
          Record.update
          travel_back
          record4.reload
          record5.reload
          record6.reload
        end
        
        let!(:record7) { Record.where(:date => mondaybeforelastmonday+7).first } # 19/01/2015
        
        specify do
          expect(Record.count).to eq(7)
          
          expect(record4.nb_submissions).to eq(1)
          expect(record4.complete).to eq(true)
          expect(record4.avg_correction_time).to eq(23.25)
          
          expect(record5.nb_submissions).to eq(1)
          expect(record5.complete).to eq(true)
          expect(record5.avg_correction_time).to eq(16.5)
          
          expect(record6.nb_submissions).to eq(0)
          expect(record6.complete).to eq(true)
          expect(record6.avg_correction_time).to eq(0.0)
          
          expect(record7.nb_submissions).to eq(1)
          expect(record7.complete).to eq(false)
        end
      end
    end
  end
end
