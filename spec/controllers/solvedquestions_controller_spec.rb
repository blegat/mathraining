# -*- coding: utf-8 -*-
require "spec_helper"

describe SolvedquestionsController, :type => :controller do

  let(:admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }

  let!(:chapter) { FactoryGirl.create(:chapter, online: true, name: "Mon chapitre") }
  let!(:prerequisite) { FactoryGirl.create(:chapter, online: true, name: "Mon chapitre prérequis") }
  let!(:question) { FactoryGirl.create(:exercise, chapter: chapter, online: true) }
  
  before { chapter.prerequisites << prerequisite }

  describe "create" do
    describe "for visitor" do
      before { post :create, :params => { :question_id => question.id, :solvedquestion => {:guess => question.answer} } }
      specify { expect(response).to render_template("errors/access_refused") }
    end
    
    describe "for user" do
      before { sign_in_controller user }
      
      describe "without completed prerequisite" do
        before { post :create, :params => { :question_id => question.id, :solvedquestion => {:guess => question.answer} } }
        specify { expect(response).to render_template("errors/access_refused") }
      end
      
      describe "with completed prerequisite" do
        before do
          user.chapters << prerequisite
          post :create, :params => { :question_id => question.id, :solvedquestion => {:guess => question.answer} }
        end
        specify { expect(response).to redirect_to(chapter_path(chapter, :type => 5, :which => question.id)) }
      end
      
      describe "if not the first try" do
        let!(:previous_solvedquestion) { FactoryGirl.create(:solvedquestion, question: question, user: user, correct: false, guess: question.answer-1, nb_guess: 1) }
        let!(:num_solvedquestions) { Solvedquestion.count }
        before do
          user.chapters << prerequisite
          post :create, :params => { :question_id => question.id, :solvedquestion => {:guess => question.answer} }
          previous_solvedquestion.reload
        end
        specify do
          # Should redirect without doing anything
          expect(response).to redirect_to(chapter_path(chapter, :type => 5, :which => question.id))
          expect(previous_solvedquestion.correct).to eq(false)
          expect(Solvedquestion.count).to eq(num_solvedquestions)
        end
      end
    end
    
    describe "for admin" do
      before do
        sign_in_controller admin
        post :create, :params => { :question_id => question.id, :solvedquestion => {:guess => question.answer} }
      end
      specify { expect(response).to render_template("errors/access_refused") }
    end
  end
  
  describe "update" do # NB: :id of solvedquestion is not used in update
    describe "for visitor" do
      before { patch :update, :params => { :id => 1, :question_id => question.id, :solvedquestion => {:guess => question.answer} } }
      specify { expect(response).to render_template("errors/access_refused") }
    end
    
    describe "for user" do
      before { sign_in_controller user }
      
      describe "without completed prerequisite" do
        before { patch :update, :params => { :id => 1, :question_id => question.id, :solvedquestion => {:guess => question.answer} } }
        specify { expect(response).to render_template("errors/access_refused") }
      end
      
      describe "with completed prerequisite" do
        let!(:previous_solvedquestion) { FactoryGirl.create(:solvedquestion, question: question, user: user, correct: false, guess: question.answer-1, nb_guess: 1) }
        before do
          user.chapters << prerequisite
          patch :update, :params => { :id => previous_solvedquestion.id, :question_id => question.id, :solvedquestion => {:guess => question.answer} }
          previous_solvedquestion.reload
        end
        specify do
          expect(response).to redirect_to(chapter_path(chapter, :type => 5, :which => question.id))
          expect(previous_solvedquestion.correct).to eq(true)
        end
      end
      
      describe "if the first try" do
        let!(:num_solvedquestions) { Solvedquestion.count }
        before do
          user.chapters << prerequisite
          patch :update, :params => { :id => 1, :question_id => question.id, :solvedquestion => {:guess => question.answer} }
        end
        specify do
          # Should redirect without doing anything
          expect(response).to redirect_to(chapter_path(chapter, :type => 5, :which => question.id))
          expect(Solvedquestion.count).to eq(num_solvedquestions)
        end
      end
      
      describe "if already solved" do
        let!(:previous_solvedquestion) { FactoryGirl.create(:solvedquestion, question: question, user: user, correct: true, guess: question.answer, nb_guess: 1) }
        before do
          user.chapters << prerequisite
          patch :update, :params => { :id => previous_solvedquestion.id, :question_id => question.id, :solvedquestion => {:guess => question.answer-1} }
          previous_solvedquestion.reload
        end
        specify do
          # Should redirect without doing anything
          expect(response).to redirect_to(chapter_path(chapter, :type => 5, :which => question.id))
          expect(previous_solvedquestion.correct).to eq(true)
        end
      end
      
      describe "if did not wait enough" do
        let!(:previous_solvedquestion) { FactoryGirl.create(:solvedquestion, question: question, user: user, correct: false, guess: question.answer-1, nb_guess: 4, updated_at: DateTime.now - 1.minute) }
        before do
          user.chapters << prerequisite
          patch :update, :params => { :id => previous_solvedquestion.id, :question_id => question.id, :solvedquestion => {:guess => question.answer} }
          previous_solvedquestion.reload
        end
        specify do
          # Should redirect without doing anything
          expect(response).to redirect_to(chapter_path(chapter, :type => 5, :which => question.id))
          expect(previous_solvedquestion.nb_guess).to eq(4)
          expect(previous_solvedquestion.correct).to eq(false)
        end
      end
    end
    
    describe "for admin" do
      before do
        sign_in_controller admin
        patch :update, :params => { :id => 1, :question_id => question.id, :solvedquestion => {:guess => question.answer} }
      end
      specify { expect(response).to render_template("errors/access_refused") }
    end
  end
end
