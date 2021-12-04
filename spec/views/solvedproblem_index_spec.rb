# -*- coding: utf-8 -*-
require "spec_helper"

describe "Page solvedproblem/index" do

  subject { page }
  
  let(:user_199_with_prerequisite) { FactoryGirl.create(:user, rating: 199) }
  let(:user_200) { FactoryGirl.create(:user, rating: 200) }
  let(:user_200_with_prerequisite) { FactoryGirl.create(:user, rating: 200) }
  let(:admin) { FactoryGirl.create(:admin) }
  let(:user1) { FactoryGirl.create(:user, rating: 543) }
  let(:user2) { FactoryGirl.create(:user, rating: 345) }
  let(:user3) { FactoryGirl.create(:user, rating: 1234) }
  
  let!(:problem1) { FactoryGirl.create(:problem, online: true) }
  let!(:problem2_with_prerequisite) { FactoryGirl.create(:problem, online: true) }
  let!(:problem3) { FactoryGirl.create(:problem, online: true) }
  let!(:chapter) { FactoryGirl.create(:chapter, online: true) }
  
  let!(:submission1) { FactoryGirl.create(:submission, problem: problem1, user: user1, status: 2, created_at: DateTime.now - 4.days) }
  let!(:solvedproblem1) { FactoryGirl.create(:solvedproblem, problem: problem1, submission: submission1, user: user1, resolution_time: DateTime.now - 4.days, correction_time: DateTime.now - 2.days) }
  let!(:submission2) { FactoryGirl.create(:submission, problem: problem2_with_prerequisite, user: user2, status: 2, created_at: DateTime.now - 23.days) }
  let!(:solvedproblem2) { FactoryGirl.create(:solvedproblem, problem: problem2_with_prerequisite, submission: submission2, user: user2, resolution_time: DateTime.now - 23.days, correction_time: DateTime.now - 1.day) }
  let!(:submission3_old) { FactoryGirl.create(:submission, problem: problem3, user: user3, status: 2, created_at: DateTime.now - 36.days) }
  let!(:solvedproblem3_old) { FactoryGirl.create(:solvedproblem, problem: problem3, submission: submission3_old, user: user3, resolution_time: DateTime.now - 36.days, correction_time: DateTime.now - 34.days) }
  
  before do
    problem2_with_prerequisite.chapters << chapter
    user_199_with_prerequisite.chapters << chapter
    user_200_with_prerequisite.chapters << chapter
  end
  
  describe "visitor" do
    before { visit solvedproblems_path }
    it do
      should have_selector("h1", text: "Résolutions récentes")
      
      should have_link(user1.name, href: user_path(user1))
      should have_no_link("Problème ##{problem1.number}") # No access to this problem
      should have_content("Problème ##{problem1.number}")
      
      should have_link(user2.name, href: user_path(user2))
      should have_no_link("Problème ##{problem2_with_prerequisite.number}") # No access to this problem
      should have_content("Problème ##{problem2_with_prerequisite.number}")
      
      should have_no_link(user3.name) # Not recent enough
      should have_no_content("Problème ##{problem3.number}")
    end
  end
  
  describe "user with rating 199" do
    before do
      sign_in user_199_with_prerequisite
      visit solvedproblems_path
    end
    it do
      should have_selector("h1", text: "Résolutions récentes")
      
      should have_link(user1.name, href: user_path(user1))
      should have_no_link("Problème ##{problem1.number}") # No access to this problem
      should have_content("Problème ##{problem1.number}")
      
      should have_link(user2.name, href: user_path(user2))
      should have_no_link("Problème ##{problem2_with_prerequisite.number}") # No access to this problem
      should have_content("Problème ##{problem2_with_prerequisite.number}")
      
      should have_no_link(user3.name) # Not recent enough
      should have_no_content("Problème ##{problem3.number}")
    end
  end
  
  describe "user with rating 200" do
    before do
      sign_in user_200
      visit solvedproblems_path
    end
    it do
      should have_selector("h1", text: "Résolutions récentes")
      
      should have_link(user1.name, href: user_path(user1))
      should have_link("Problème ##{problem1.number}", href: problem_path(problem1, :sub => submission1))
      
      should have_link(user2.name, href: user_path(user2))
      should have_no_link("Problème ##{problem2_with_prerequisite.number}") # No access to this problem
      should have_content("Problème ##{problem2_with_prerequisite.number}")
      
      should have_no_link(user3.name) # Not recent enough
      should have_no_content("Problème ##{problem3.number}")
    end
  end
  
  describe "user with rating 200 and completed prerequisite" do
    before do
      sign_in user_200_with_prerequisite
      visit solvedproblems_path
    end
    it do
      should have_selector("h1", text: "Résolutions récentes")
      
      should have_link(user1.name, href: user_path(user1))
      should have_link("Problème ##{problem1.number}", href: problem_path(problem1, :sub => submission1))
      
      should have_link(user2.name, href: user_path(user2))
      should have_link("Problème ##{problem2_with_prerequisite.number}", href: problem_path(problem2_with_prerequisite, :sub => submission2))
      
      should have_no_link(user3.name) # Not recent enough
      should have_no_content("Problème ##{problem3.number}")
    end
  end
  
  describe "admin" do
    before do
      sign_in admin
      visit solvedproblems_path
    end
    it do
      should have_selector("h1", text: "Résolutions récentes")
      
      should have_link(user1.name, href: user_path(user1))
      should have_link("Problème ##{problem1.number}", href: problem_path(problem1, :sub => submission1))
      
      should have_link(user2.name, href: user_path(user2))
      should have_link("Problème ##{problem2_with_prerequisite.number}", href: problem_path(problem2_with_prerequisite, :sub => submission2))
      
      should have_no_link(user3.name) # Not recent enough
      should have_no_content("Problème ##{problem3.number}")
    end
  end
end
