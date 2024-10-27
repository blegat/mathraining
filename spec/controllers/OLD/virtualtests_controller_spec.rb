# -*- coding: utf-8 -*-
require "spec_helper"

describe VirtualtestsController, :type => :controller do

  let(:admin) { FactoryGirl.create(:admin) }
  let(:user_with_rating_199) { FactoryGirl.create(:user, rating: 199) }
  let(:user_with_rating_200) { FactoryGirl.create(:user, rating: 200) }
  
  let!(:virtualtest) { FactoryGirl.create(:virtualtest, online: true, number: 42) }
  let!(:problem) { FactoryGirl.create(:problem, online: true, level: 1, number: 1123, virtualtest: virtualtest, position: 1, statement: "Statement1") }
  let!(:chapter) { FactoryGirl.create(:chapter, online: true, name: "Mon chapitre prérequis") }
  
  before { problem.chapters << chapter }

  describe "begin_test" do
    describe "for visitor" do
      before { put :begin_test, :params => { :id => virtualtest.id } }
      specify { expect(response).to render_template("errors/access_refused") }
    end
    
    describe "for user with rating 199" do
      before do
        sign_in_controller user_with_rating_199
        put :begin_test, :params => { :id => virtualtest.id }
      end
      specify { expect(response).to render_template("errors/access_refused") }
    end
    
    describe "for user with rating 200" do
      before { sign_in_controller user_with_rating_200 }
      
      describe "without completed prerequisite" do
        before { put :begin_test, :params => { :id => virtualtest.id } }
        specify { expect(response).to render_template("errors/access_refused") }
      end
      
      describe "with completed prerequisite" do
        before do
          user_with_rating_200.chapters << chapter
          put :begin_test, :params => { :id => virtualtest.id }
        end
        specify { expect(response).to redirect_to(virtualtest_path(virtualtest)) }
      end
      
      describe "having already started that test" do
        before do
          user_with_rating_200.chapters << chapter
          Takentest.create(virtualtest: virtualtest, user: user_with_rating_200, taken_time: DateTime.now - 2.days, status: :finished)
          put :begin_test, :params => { :id => virtualtest.id }
        end
        specify { expect(response).to redirect_to(virtualtests_path) }
      end
    end
    
    describe "for admin" do
      before do
        sign_in_controller admin
        put :begin_test, :params => { :id => virtualtest.id }
      end
      specify { expect(response).to render_template("errors/access_refused") }
    end
  end
end
