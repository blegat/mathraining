# -*- coding: utf-8 -*-
require "spec_helper"

describe UnsolvedquestionsController, :type => :controller do

  let(:admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }

  let!(:chapter) { FactoryGirl.create(:chapter, online: true, name: "Mon chapitre") }
  let!(:prerequisite) { FactoryGirl.create(:chapter, online: true, name: "Mon chapitre prérequis") }
  let!(:question) { FactoryGirl.create(:exercise_decimal, chapter: chapter, online: true) }
  
  before { chapter.prerequisites << prerequisite }

  describe "create" do
    describe "for visitor" do
      before { post :create, :params => { :question_id => question.id, :unsolvedquestion => {:guess => question.answer} } }
      specify { expect(response).to render_template("errors/access_refused") }
    end
    
    describe "for user" do
      before { sign_in_controller user }
      
      describe "without completed prerequisite" do
        before { post :create, :params => { :question_id => question.id, :unsolvedquestion => {:guess => question.answer} } }
        specify { expect(response).to render_template("errors/access_refused") }
      end
      
      describe "with completed prerequisite" do
        before do
          user.chapters << prerequisite
          post :create, :params => { :question_id => question.id, :unsolvedquestion => {:guess => question.answer} }
        end
        specify { expect(response).to redirect_to(chapter_path(chapter, :type => 5, :which => question.id)) }
      end
      
      describe "if not the first try" do
        let!(:previous_unsolvedquestion) { FactoryGirl.create(:unsolvedquestion, question: question, user: user, guess: question.answer-1, nb_guess: 1) }
        before do
          user.chapters << prerequisite
          post :create, :params => { :question_id => question.id, :unsolvedquestion => {:guess => question.answer} }
          previous_unsolvedquestion.reload
        end
        specify do
          # Should redirect without doing anything
          expect(response).to redirect_to(chapter_path(chapter, :type => 5, :which => question.id))
          expect(previous_unsolvedquestion.nb_guess).to eq(1)
          expect(Solvedquestion.where(:user => user, :question => question).count).to eq(0)
          expect(Unsolvedquestion.where(:user => user, :question => question).count).to eq(1)
        end
      end
    end
    
    describe "for admin" do
      before do
        sign_in_controller admin
        post :create, :params => { :question_id => question.id, :unsolvedquestion => {:guess => question.answer} }
      end
      specify { expect(response).to render_template("errors/access_refused") }
    end
  end
  
  describe "update" do # NB: :id of unsolvedquestion is not used in update
    describe "for visitor" do
      before { patch :update, :params => { :id => 1, :question_id => question.id, :unsolvedquestion => {:guess => question.answer} } }
      specify { expect(response).to render_template("errors/access_refused") }
    end
    
    describe "for user" do
      before { sign_in_controller user }
      
      describe "without completed prerequisite" do
        before { patch :update, :params => { :id => 1, :question_id => question.id, :unsolvedquestion => {:guess => question.answer} } }
        specify { expect(response).to render_template("errors/access_refused") }
      end
      
      describe "with completed prerequisite" do
        let!(:previous_unsolvedquestion) { FactoryGirl.create(:unsolvedquestion, question: question, user: user, guess: question.answer-1, nb_guess: 1) }
        before do
          user.chapters << prerequisite
          patch :update, :params => { :id => previous_unsolvedquestion.id, :question_id => question.id, :unsolvedquestion => {:guess => question.answer} }
        end
        specify do
          expect(response).to redirect_to(chapter_path(chapter, :type => 5, :which => question.id))
          expect(Solvedquestion.where(:user => user, :question => question).count).to eq(1)
          expect(Unsolvedquestion.where(:user => user, :question => question).count).to eq(0)
        end
      end
      
      describe "if the first try" do
        before do
          user.chapters << prerequisite
          patch :update, :params => { :id => 1, :question_id => question.id, :unsolvedquestion => {:guess => question.answer} }
        end
        specify { expect(response).to render_template("errors/access_refused") }
      end
      
      describe "if already solved" do
        let!(:previous_unsolvedquestion) { FactoryGirl.create(:unsolvedquestion, question: question, user: user, guess: question.answer, nb_guess: 1) }
        before do
          user.chapters << prerequisite
          patch :update, :params => { :id => previous_unsolvedquestion.id, :question_id => question.id, :unsolvedquestion => {:guess => question.answer-1} }
        end
        specify do
          # Should redirect without doing anything
          expect(response).to redirect_to(chapter_path(chapter, :type => 5, :which => question.id))
          expect(Solvedquestion.where(:user => user, :question => question).count).to eq(0)
          expect(Unsolvedquestion.where(:user => user, :question => question).count).to eq(1)
        end
      end
      
      describe "if did not wait enough" do
        let!(:previous_unsolvedquestion) { FactoryGirl.create(:unsolvedquestion, question: question, user: user, guess: question.answer-1, nb_guess: 4, last_guess_time: DateTime.now - 1.minute) }
        before do
          user.chapters << prerequisite
          patch :update, :params => { :id => previous_unsolvedquestion.id, :question_id => question.id, :unsolvedquestion => {:guess => question.answer} }
          previous_unsolvedquestion.reload
        end
        specify do
          # Should redirect without doing anything
          expect(response).to redirect_to(chapter_path(chapter, :type => 5, :which => question.id))
          expect(previous_unsolvedquestion.nb_guess).to eq(4)
          expect(Solvedquestion.where(:user => user, :question => question).count).to eq(0)
          expect(Unsolvedquestion.where(:user => user, :question => question).count).to eq(1)
        end
      end
    end
    
    describe "for admin" do
      before do
        sign_in_controller admin
        patch :update, :params => { :id => 1, :question_id => question.id, :unsolvedquestion => {:guess => question.answer} }
      end
      specify { expect(response).to render_template("errors/access_refused") }
    end
  end
end
