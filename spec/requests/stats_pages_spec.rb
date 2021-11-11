# -*- coding: utf-8 -*-
require "spec_helper"

describe "Stats pages" do

  subject { page }

  let(:user1) { FactoryGirl.create(:user) }
  let(:user2) { FactoryGirl.create(:user) }
  let(:admin) { FactoryGirl.create(:admin) }
  
  let!(:section) { FactoryGirl.create(:section) }
  
  let!(:chapter1) { FactoryGirl.create(:chapter, section: section, online: true) }
  let!(:chapter2) { FactoryGirl.create(:chapter, section: section, online: true) }
  
  let!(:exercise11) { FactoryGirl.create(:exercise, chapter: chapter1, online: true, position: 1, level: 1) }
  let!(:exercise12) { FactoryGirl.create(:exercise, chapter: chapter1, online: true, position: 2, level: 2) }
  let!(:exercise13_offline) { FactoryGirl.create(:exercise, chapter: chapter1, online: false, position: 3, level: 3) }
  let!(:exercise21) { FactoryGirl.create(:exercise, chapter: chapter2, online: true, position: 1, level: 1) }
  let!(:exercise22) { FactoryGirl.create(:exercise, chapter: chapter2, online: true, position: 2, level: 2) }
  
  describe "user" do
    before { sign_in user1 }
    
    describe "tries the first exercise of a chapter" do
      before do
        visit chapter_path(chapter1, :type => 5, :which => exercise11)
        fill_in "solvedquestion[guess]", with: exercise11.answer + 12
        click_button "Soumettre"
        chapter1.reload
      end
      specify do
        expect(chapter1.nb_tries).to eq(1)
        expect(chapter1.nb_solved).to eq(0)
      end
    end
    
    describe "solves the first exercise of a chapter" do
      before do
        visit chapter_path(chapter1, :type => 5, :which => exercise11)
        fill_in "solvedquestion[guess]", with: exercise11.answer
        click_button "Soumettre"
        chapter1.reload
      end
      specify do
        expect(chapter1.nb_tries).to eq(1)
        expect(chapter1.nb_solved).to eq(0)
      end
      
      describe "and solves the second exercise of the chapter" do
        before do
          visit chapter_path(chapter1, :type => 5, :which => exercise12)
          fill_in "solvedquestion[guess]", with: exercise12.answer
          click_button "Soumettre"
          chapter1.reload
        end
        specify do
          expect(chapter1.nb_tries).to eq(1)
          expect(chapter1.nb_solved).to eq(1)
        end
        
        describe "and recomputes the chapter stats" do
          before do
            # Change nb_tries and nb_solved in a wrong way
            chapter1.nb_tries = 42
            chapter1.nb_solved = 42
            chapter1.save
            chapter2.nb_tries = 42
            chapter2.nb_solved = 42
            chapter2.save
            Chapter.update_stats
            chapter1.reload
            chapter2.reload
          end
          specify do
            expect(chapter1.nb_tries).to eq(1)
            expect(chapter1.nb_solved).to eq(1)
            expect(chapter2.nb_tries).to eq(0)
            expect(chapter2.nb_solved).to eq(0)
          end
        end
      end
    end
  end
  
  describe "cron job" do
  
    describe "computes solvedquestion stats" do
      let!(:now) { DateTime.now }
      let!(:mondaybeforelastmonday) { Record.get_monday_before_last_monday(now.in_time_zone.to_date) }
      let!(:solvedq11) { FactoryGirl.create(:solvedquestion, user: user1, question: exercise11, correct: true, guess: exercise11.answer, resolutiontime: now-28.days) }
      let!(:solvedq12) { FactoryGirl.create(:solvedquestion, user: user1, question: exercise12, correct: true, guess: exercise12.answer, resolutiontime: now-28.days) }
      let!(:solvedq21) { FactoryGirl.create(:solvedquestion, user: user1, question: exercise21, correct: false, guess: exercise21.answer + 1, resolutiontime: now-21.days) }
      let!(:solvedq22) { FactoryGirl.create(:solvedquestion, user: user1, question: exercise22, correct: true, guess: exercise22.answer, resolutiontime: now-14.days) }
      
      before { Record.update }
      
      # NB: We can test that there is no record for mondaybeforelastmonday + 7 but it can be wrong if db is run exactly monday at midnight...
      let!(:record1) { Record.where(:date => mondaybeforelastmonday - 21).first }
      let!(:record2) { Record.where(:date => mondaybeforelastmonday - 14).first }
      let!(:record3) { Record.where(:date => mondaybeforelastmonday - 7).first }
      let!(:record4) { Record.where(:date => mondaybeforelastmonday).first }
      
      specify do
        expect(record1.number_solved).to eq(2)
        expect(record2.number_solved).to eq(0)
        expect(record3.number_solved).to eq(1)
        expect(record4.number_solved).to eq(0)
      end
    end
    
    describe "computes submission stats" do
      let!(:now) { DateTime.now }
      let!(:mondaybeforelastmonday) { Record.get_monday_before_last_monday(now.in_time_zone.to_date) }
      let!(:problem1) { FactoryGirl.create(:problem, section: section, online: true, number: 1111, level: 1) }
      let!(:problem2) { FactoryGirl.create(:problem, section: section, online: true, number: 1112, level: 2) }
      let!(:problem3) { FactoryGirl.create(:problem, section: section, online: true, number: 1113, level: 3) }
      let!(:submission11) { FactoryGirl.create(:submission, user: user1, problem: problem1, status: 2, created_at: now-28.days) } # Correct
      let!(:correction11) { FactoryGirl.create(:correction, user: admin, submission: submission11,     created_at: now-26.days) } # 2 days later
      let!(:submission12) { FactoryGirl.create(:submission, user: user1, problem: problem2, status: 2, created_at: now-21.days) } # Correct
      let!(:correction12) { FactoryGirl.create(:correction, user: admin, submission: submission12,     created_at: now-20.days) } # 1 day later
      let!(:submission13) { FactoryGirl.create(:submission, user: user1, problem: problem3, status: 1, created_at: now-21.days) } # Wrong
      let!(:correction13) { FactoryGirl.create(:correction, user: admin, submission: submission13,     created_at: now-19.days) } # 2 days later
      let!(:submission21) { FactoryGirl.create(:submission, user: user2, problem: problem1, status: 1, created_at: now-21.days) } # Wrong
      let!(:correction21) { FactoryGirl.create(:correction, user: admin, submission: submission21,     created_at: now-17.days) } # 4 days later
      let!(:submission22) { FactoryGirl.create(:submission, user: user2, problem: problem2, status: 0, created_at: now-14.days) } # Not checked
      let!(:submission23) { FactoryGirl.create(:submission, user: user2, problem: problem3, status: -1, created_at: now-14.days) } # Draft
      
      before { Record.update }
      
      # We can test that there is no record for mondaybeforelastmonday + 7 but it can be wrong if db is run exactly monday at midnight...
      let!(:record1) { Record.where(:date => mondaybeforelastmonday - 21).first }
      let!(:record2) { Record.where(:date => mondaybeforelastmonday - 14).first }
      let!(:record3) { Record.where(:date => mondaybeforelastmonday - 7).first }
      let!(:record4) { Record.where(:date => mondaybeforelastmonday).first }
      
      specify do
        expect(record1.number_submission).to eq(1)
        expect(record1.complete).to eq(true)
        expect(record1.correction_time).to eq(2.0)
        
        expect(record2.number_submission).to eq(3)
        expect(record2.complete).to eq(true)
        expect(record2.correction_time).to eq(7.0/3.0)
        
        expect(record3.number_submission).to eq(1)
        expect(record3.complete).to eq(false)
        
        expect(record4.number_submission).to eq(0)
        expect(record4.complete).to eq(true)
        expect(record4.correction_time).to eq(0.0)
      end
    end
    
    describe "computes visitor stats" do
      let!(:today) { DateTime.now.in_time_zone.to_date }
      before do
        user1.last_connexion = today - 2
        user1.save
        user2.last_connexion = today - 1
        user2.save
        admin.last_connexion = today - 1
        admin.save
        Visitor.compute
      end
      let!(:visitor_data) { Visitor.where(:date => today - 1).first }
      specify do
        expect(visitor_data.number_user).to eq(1)
        expect(visitor_data.number_admin).to eq(1)
      end
    end
  end
end
