# -*- coding: utf-8 -*-
require "spec_helper"

describe "problems/index.html.erb", type: :view, problem: true do

  subject { rendered }

  let(:admin) { FactoryBot.create(:admin) }
  let(:user_with_rating_199) { FactoryBot.create(:user, rating: 199) }
  let(:user) { FactoryBot.create(:advanced_user) }
  let!(:section) { FactoryBot.create(:section) }
  let!(:chapter1) { FactoryBot.create(:chapter, section: section, online: true, name: "Mon chapitre prérequis") }
  let!(:chapter2) { FactoryBot.create(:chapter, section: section, online: true, name: "Mon autre chapitre prérequis") }
  let!(:online_problem) { FactoryBot.create(:problem, section: section, online: true, level: 1, number: 1123) }
  let!(:online_problem_with_one_prerequisite) { FactoryBot.create(:problem, section: section, online: true, level: 2, number: 1124) }
  let!(:online_problem_with_two_prerequisites) { FactoryBot.create(:problem, section: section, online: true, level: 5, number: 1578) }
  let!(:offline_problem) { FactoryBot.create(:problem, section: section, online: false, level: 1, number: 1134) }
  let!(:online_virtualtest) { FactoryBot.create(:virtualtest, online: true, number: 42, duration: 10) }
  let!(:problem_in_online_virtualtest) { FactoryBot.create(:problem, section: section, online: true, level: 2, number: 1256, position: 1, virtualtest: online_virtualtest) }
  let!(:problem_with_prerequisite_in_online_virtualtest) { FactoryBot.create(:problem, section: section, online: true, level: 4, number: 1456, position: 2, virtualtest: online_virtualtest) }
  let!(:offline_virtualtest) { FactoryBot.create(:virtualtest, online: false, number: 23, duration: 15) }
  let!(:problem_in_offline_virtualtest) { FactoryBot.create(:problem, section: section, online: true, level: 3, number: 1341, position: 1, virtualtest: offline_virtualtest) }
  
  before do
    assign(:section, section)
    online_problem_with_one_prerequisite.chapters << chapter1
    online_problem_with_two_prerequisites.chapters << chapter1
    online_problem_with_two_prerequisites.chapters << chapter2
    problem_with_prerequisite_in_online_virtualtest.chapters << chapter1
  end
  
  describe "visitor" do
    it "renders the message about needed rating" do
      render template: "problems/index"
      should have_selector("h1", text: section.name)
      should have_selector("p", text: "Les problèmes ne sont accessibles qu'aux utilisateurs ayant un score d'au moins 200.")
    end
  end
  
  describe "user with rating 199" do
    before { sign_in_view(user_with_rating_199) }
    
    it "renders the message about needed rating" do
      render template: "problems/index"
      should have_selector("h1", text: section.name)
      should have_selector("p", text: "Les problèmes ne sont accessibles qu'aux utilisateurs ayant un score d'au moins 200.")
    end
  end
  
  describe "user with rating 200" do
    before { sign_in_view(user) }

    describe "having completed no chapter" do
      it "renders the expected problems" do
        render template: "problems/index"
        should have_selector("h1", text: section.name)
        should have_no_selector("div", text: "Les problèmes ne sont accessibles qu'aux utilisateurs ayant un score d'au moins 200.")
        
        should have_selector("h3", text: "Niveau 1")
        should have_selector("h3", text: "Niveau 2")
        should have_selector("h3", text: "Niveau 3")
        should have_selector("h3", text: "Niveau 4")
        should have_selector("h3", text: "Niveau 5")
        
        should have_selector("table", class: "yellowy", text: online_problem.statement) # Level 1
        should have_no_selector("table", text: online_problem_with_one_prerequisite.statement)
        should have_no_selector("table", text: online_problem_with_two_prerequisites.statement)
        should have_no_selector("table", text: offline_problem.statement) 
        should have_no_selector("table", text: problem_in_online_virtualtest.statement) 
        should have_no_selector("table", text: problem_with_prerequisite_in_online_virtualtest.statement) 
        should have_no_selector("table", text: problem_in_offline_virtualtest.statement)
        
        should have_content("Chaque problème de niveau 1 vaut 15 points.")
        should have_no_content("Chaque problème de niveau 2 vaut 30 points.")
        should have_no_content("Chaque problème de niveau 3 vaut 45 points.")
        should have_no_content("Chaque problème de niveau 4 vaut 60 points.")
        should have_no_content("Chaque problème de niveau 5 vaut 75 points.")
        
        should have_no_content("Aucun problème de niveau 1 n'est disponible.")
        should have_content("Aucun problème de niveau 2 n'est disponible.")
        should have_content("Aucun problème de niveau 3 n'est disponible.")
        should have_content("Aucun problème de niveau 4 n'est disponible.")
        should have_content("Aucun problème de niveau 5 n'est disponible.")
      end
    end
    
    describe "having completed first chapter" do
      before { user.chapters << chapter1 }
      
      it "renders the expected problems" do
        render template: "problems/index"
        should have_selector("h1", text: section.name)
        should have_no_selector("div", text: "Les problèmes ne sont accessibles qu'aux utilisateurs ayant un score d'au moins 200.")
        
        should have_selector("h3", text: "Niveau 1")
        should have_selector("h3", text: "Niveau 2")
        should have_selector("h3", text: "Niveau 3")
        should have_selector("h3", text: "Niveau 4")
        should have_selector("h3", text: "Niveau 5")
        
        should have_selector("table", class: "yellowy", text: online_problem.statement) # Level 1
        should have_selector("table", class: "yellowy", text: online_problem_with_one_prerequisite.statement) # Level 2
        should have_no_selector("table", text: online_problem_with_two_prerequisites.statement)
        should have_no_selector("table", text: offline_problem.statement) 
        should have_no_selector("table", text: problem_in_online_virtualtest.statement) 
        should have_no_selector("table", text: problem_with_prerequisite_in_online_virtualtest.statement) 
        should have_no_selector("table", text: problem_in_offline_virtualtest.statement)
        
        should have_content("Chaque problème de niveau 1 vaut 15 points.")
        should have_content("Chaque problème de niveau 2 vaut 30 points.")
        should have_no_content("Chaque problème de niveau 3 vaut 45 points.")
        should have_no_content("Chaque problème de niveau 4 vaut 60 points.")
        should have_no_content("Chaque problème de niveau 5 vaut 75 points.")
        
        should have_no_content("Aucun problème de niveau 1 n'est disponible.")
        should have_no_content("Aucun problème de niveau 2 n'est disponible.")
        should have_content("Aucun problème de niveau 3 n'est disponible.")
        should have_content("Aucun problème de niveau 4 n'est disponible.")
        should have_content("Aucun problème de niveau 5 n'est disponible.")
      end
    end
    
    describe "having completed second chapter" do
      before { user.chapters << chapter2 }
      
      it "renders the expected problems" do
        render template: "problems/index"
        should have_selector("h1", text: section.name)
        should have_no_selector("div", text: "Les problèmes ne sont accessibles qu'aux utilisateurs ayant un score d'au moins 200.")
        
        should have_selector("h3", text: "Niveau 1")
        should have_selector("h3", text: "Niveau 2")
        should have_selector("h3", text: "Niveau 3")
        should have_selector("h3", text: "Niveau 4")
        should have_selector("h3", text: "Niveau 5")
        
        should have_selector("table", class: "yellowy", text: online_problem.statement) # Level 1
        should have_no_selector("table", text: online_problem_with_one_prerequisite.statement)
        should have_no_selector("table", text: online_problem_with_two_prerequisites.statement)
        should have_no_selector("table", text: offline_problem.statement) 
        should have_no_selector("table", text: problem_in_online_virtualtest.statement) 
        should have_no_selector("table", text: problem_with_prerequisite_in_online_virtualtest.statement) 
        should have_no_selector("table", text: problem_in_offline_virtualtest.statement)
        
        should have_content("Chaque problème de niveau 1 vaut 15 points.")
        should have_no_content("Chaque problème de niveau 2 vaut 30 points.")
        should have_no_content("Chaque problème de niveau 3 vaut 45 points.")
        should have_no_content("Chaque problème de niveau 4 vaut 60 points.")
        should have_no_content("Chaque problème de niveau 5 vaut 75 points.")
        
        should have_no_content("Aucun problème de niveau 1 n'est disponible.")
        should have_content("Aucun problème de niveau 2 n'est disponible.")
        should have_content("Aucun problème de niveau 3 n'est disponible.")
        should have_content("Aucun problème de niveau 4 n'est disponible.")
        should have_content("Aucun problème de niveau 5 n'est disponible.")
      end
    end
    
    describe "having completed both chapters" do
      before do
        user.chapters << chapter1
        user.chapters << chapter2
      end
      
      it "renders the expected problems" do
        render template: "problems/index"
        should have_selector("h1", text: section.name)
        should have_no_selector("div", text: "Les problèmes ne sont accessibles qu'aux utilisateurs ayant un score d'au moins 200.")
        
        should have_selector("h3", text: "Niveau 1")
        should have_selector("h3", text: "Niveau 2")
        should have_selector("h3", text: "Niveau 3")
        should have_selector("h3", text: "Niveau 4")
        should have_selector("h3", text: "Niveau 5")
        
        should have_selector("table", class: "yellowy", text: online_problem.statement) # Level 1
        should have_selector("table", class: "yellowy", text: online_problem_with_one_prerequisite.statement) # Level 2
        should have_selector("table", class: "yellowy", text: online_problem_with_two_prerequisites.statement) # Level 5
        should have_no_selector("table", text: offline_problem.statement) 
        should have_no_selector("table", text: problem_in_online_virtualtest.statement) 
        should have_no_selector("table", text: problem_with_prerequisite_in_online_virtualtest.statement) 
        should have_no_selector("table", text: problem_in_offline_virtualtest.statement)
        
        should have_content("Chaque problème de niveau 1 vaut 15 points.")
        should have_content("Chaque problème de niveau 2 vaut 30 points.")
        should have_no_content("Chaque problème de niveau 3 vaut 45 points.")
        should have_no_content("Chaque problème de niveau 4 vaut 60 points.")
        should have_content("Chaque problème de niveau 5 vaut 75 points.")
        
        should have_no_content("Aucun problème de niveau 1 n'est disponible.")
        should have_no_content("Aucun problème de niveau 2 n'est disponible.")
        should have_content("Aucun problème de niveau 3 n'est disponible.")
        should have_content("Aucun problème de niveau 4 n'est disponible.")
        should have_no_content("Aucun problème de niveau 5 n'est disponible.")
      end
    end
    
    describe "having completed both chapters and started the test" do
      before do
        user.chapters << chapter1
        user.chapters << chapter2
        Takentest.create(:user => user, :virtualtest => online_virtualtest, :status => :in_progress, :taken_time => DateTime.now - 2.minutes)
      end
      
      it "renders the expected problems" do
        render template: "problems/index"
        should have_selector("h1", text: section.name)
        should have_no_selector("div", text: "Les problèmes ne sont accessibles qu'aux utilisateurs ayant un score d'au moins 200.")
        
        should have_selector("h3", text: "Niveau 1")
        should have_selector("h3", text: "Niveau 2")
        should have_selector("h3", text: "Niveau 3")
        should have_selector("h3", text: "Niveau 4")
        should have_selector("h3", text: "Niveau 5")
        
        should have_selector("table", class: "yellowy", text: online_problem.statement) # Level 1
        should have_selector("table", class: "yellowy", text: online_problem_with_one_prerequisite.statement) # Level 2
        should have_selector("table", class: "yellowy", text: online_problem_with_two_prerequisites.statement) # Level 5
        should have_no_selector("table", text: offline_problem.statement) 
        should have_no_selector("table", text: problem_in_online_virtualtest.statement) 
        should have_no_selector("table", text: problem_with_prerequisite_in_online_virtualtest.statement) 
        should have_no_selector("table", text: problem_in_offline_virtualtest.statement)
        
        should have_content("Chaque problème de niveau 1 vaut 15 points.")
        should have_content("Chaque problème de niveau 2 vaut 30 points.")
        should have_no_content("Chaque problème de niveau 3 vaut 45 points.")
        should have_no_content("Chaque problème de niveau 4 vaut 60 points.")
        should have_content("Chaque problème de niveau 5 vaut 75 points.")
        
        should have_no_content("Aucun problème de niveau 1 n'est disponible.")
        should have_no_content("Aucun problème de niveau 2 n'est disponible.")
        should have_content("Aucun problème de niveau 3 n'est disponible.")
        should have_content("Aucun problème de niveau 4 n'est disponible.")
        should have_no_content("Aucun problème de niveau 5 n'est disponible.")
      end
    end
    
    describe "having completed both chapters and finished the test" do
      before do
        user.chapters << chapter1
        user.chapters << chapter2
        Takentest.create(:user => user, :virtualtest => online_virtualtest, :status => :finished, :taken_time => DateTime.now - 2.days)
      end
      
      it "renders the expected problems" do
        render template: "problems/index"
        should have_selector("h1", text: section.name)
        should have_no_selector("div", text: "Les problèmes ne sont accessibles qu'aux utilisateurs ayant un score d'au moins 200.")
        
        should have_selector("h3", text: "Niveau 1")
        should have_selector("h3", text: "Niveau 2")
        should have_selector("h3", text: "Niveau 3")
        should have_selector("h3", text: "Niveau 4")
        should have_selector("h3", text: "Niveau 5")
        
        should have_selector("table", class: "yellowy", text: online_problem.statement) # Level 1
        should have_selector("table", class: "yellowy", text: online_problem_with_one_prerequisite.statement) # Level 2
        should have_selector("table", class: "yellowy", text: online_problem_with_two_prerequisites.statement) # Level 5
        should have_no_selector("table", text: offline_problem.statement) 
        should have_selector("table", class: "yellowy", text: problem_in_online_virtualtest.statement)  # Level 2
        should have_selector("table", class: "yellowy", text: problem_with_prerequisite_in_online_virtualtest.statement) # Level 4
        should have_no_selector("table", text: problem_in_offline_virtualtest.statement)
        
        should have_content("Chaque problème de niveau 1 vaut 15 points.")
        should have_content("Chaque problème de niveau 2 vaut 30 points.")
        should have_no_content("Chaque problème de niveau 3 vaut 45 points.")
        should have_content("Chaque problème de niveau 4 vaut 60 points.")
        should have_content("Chaque problème de niveau 5 vaut 75 points.")
        
        should have_no_content("Aucun problème de niveau 1 n'est disponible.")
        should have_no_content("Aucun problème de niveau 2 n'est disponible.")
        should have_content("Aucun problème de niveau 3 n'est disponible.")
        should have_no_content("Aucun problème de niveau 4 n'est disponible.")
        should have_no_content("Aucun problème de niveau 5 n'est disponible.")
      end
    end
    
    describe "with many submissions" do
      let!(:sub1) { FactoryBot.create(:submission, problem: online_problem, user: user, status: :correct) }
      let!(:sp1) { FactoryBot.create(:solvedproblem, problem: online_problem, user: user, submission: sub1) }
      let!(:sub2) { FactoryBot.create(:submission, problem: online_problem_with_one_prerequisite, user: user, status: :wrong) }
      let!(:sub3) { FactoryBot.create(:submission, problem: online_problem_with_one_prerequisite, user: user, status: :wrong_to_read) }
      let!(:sub4) { FactoryBot.create(:submission, problem: online_problem_with_two_prerequisites, user: user, status: :wrong) }
      let!(:sub5) { FactoryBot.create(:submission, problem: online_problem_with_two_prerequisites, user: user, status: :waiting) }
      let!(:sub6) { FactoryBot.create(:submission, problem: problem_in_online_virtualtest, user: user, status: :draft) }
      let!(:sub7) { FactoryBot.create(:submission, problem: problem_with_prerequisite_in_online_virtualtest, user: user, status: :wrong_to_read) }
      let!(:sub8) { FactoryBot.create(:submission, problem: problem_with_prerequisite_in_online_virtualtest, user: user, status: :waiting) }
      let!(:sub9) { FactoryBot.create(:submission, problem: problem_with_prerequisite_in_online_virtualtest, user: user, status: :correct) }
      let!(:sp9) { FactoryBot.create(:solvedproblem, problem: problem_with_prerequisite_in_online_virtualtest, user: user, submission: sub9) }
      
      before do
        user.chapters << chapter1
        user.chapters << chapter2
        Takentest.create(:user => user, :virtualtest => online_virtualtest, :status => :finished, :taken_time => DateTime.now - 2.days)
      end
      
      it "renders the expected problems" do
        render template: "problems/index"
        should have_selector("h1", text: section.name)
        should have_no_selector("div", text: "Les problèmes ne sont accessibles qu'aux utilisateurs ayant un score d'au moins 200.")
        
        should have_selector("h3", text: "Niveau 1")
        should have_selector("h3", text: "Niveau 2")
        should have_selector("h3", text: "Niveau 3")
        should have_selector("h3", text: "Niveau 4")
        should have_selector("h3", text: "Niveau 5")
        
        should have_selector("table", class: "greeny", text: online_problem.statement) # Level 1
        should have_content(online_problem.origin)
        should have_selector("table", class: "redy", text: online_problem_with_one_prerequisite.statement) # Level 2
        should have_no_content(online_problem_with_one_prerequisite.origin)
        should have_selector("table", class: "orangey", text: online_problem_with_two_prerequisites.statement) # Level 5
        should have_no_content(online_problem_with_two_prerequisites.origin)
        should have_no_selector("table", text: offline_problem.statement)
        should have_selector("table", class: "yellowy", text: problem_in_online_virtualtest.statement)  # Level 2
        should have_no_content(problem_in_online_virtualtest.origin)
        should have_selector("table", class: "yellowy", text: "(Vous avez un brouillon enregistré pour ce problème.)")
        should have_selector("table", class: "greeny", text: problem_with_prerequisite_in_online_virtualtest.statement)  # Level 4
        should have_content(problem_with_prerequisite_in_online_virtualtest.origin)
        should have_no_selector("table", text: problem_in_offline_virtualtest.statement)
        
        should have_content("Chaque problème de niveau 1 vaut 15 points.")
        should have_content("Chaque problème de niveau 2 vaut 30 points.")
        should have_no_content("Chaque problème de niveau 3 vaut 45 points.")
        should have_content("Chaque problème de niveau 4 vaut 60 points.")
        should have_content("Chaque problème de niveau 5 vaut 75 points.")
        
        should have_no_content("Aucun problème de niveau 1 n'est disponible.")
        should have_no_content("Aucun problème de niveau 2 n'est disponible.")
        should have_content("Aucun problème de niveau 3 n'est disponible.")
        should have_no_content("Aucun problème de niveau 4 n'est disponible.")
        should have_no_content("Aucun problème de niveau 5 n'est disponible.")
      end
    end
    
    describe "with many submissions (2)" do
      let!(:sub1) { FactoryBot.create(:submission, problem: online_problem, user: user, status: :correct) }
      let!(:sub2) { FactoryBot.create(:submission, problem: online_problem, user: user, status: :correct) }
      let!(:sp1) { FactoryBot.create(:solvedproblem, problem: online_problem, user: user, submission: sub2) }
      let!(:sub2) { FactoryBot.create(:submission, problem: online_problem_with_one_prerequisite, user: user, status: :plagiarized) }
      let!(:sub3) { FactoryBot.create(:submission, problem: online_problem_with_two_prerequisites, user: user, status: :wrong_to_read) }
      let!(:sub4) { FactoryBot.create(:submission, problem: online_problem_with_two_prerequisites, user: user, status: :wrong) }
      let!(:sub5) { FactoryBot.create(:submission, problem: online_problem_with_two_prerequisites, user: user, status: :draft) }
      let!(:sub6) { FactoryBot.create(:submission, problem: problem_in_online_virtualtest, user: user, status: :waiting) }
      let!(:sub7) { FactoryBot.create(:submission, problem: problem_with_prerequisite_in_online_virtualtest, user: user, status: :wrong_to_read) }
      let!(:sub8) { FactoryBot.create(:submission, problem: problem_with_prerequisite_in_online_virtualtest, user: user, status: :wrong_to_read) }
      let!(:sub9) { FactoryBot.create(:submission, problem: problem_with_prerequisite_in_online_virtualtest, user: user, status: :plagiarized) }
      
      before do
        user.chapters << chapter1
        user.chapters << chapter2
        Takentest.create(:user => user, :virtualtest => online_virtualtest, :status => :finished, :taken_time => DateTime.now - 2.days)
      end
      
      it "renders the expected problems" do
        render template: "problems/index"
        should have_selector("h1", text: section.name)
        should have_no_selector("div", text: "Les problèmes ne sont accessibles qu'aux utilisateurs ayant un score d'au moins 200.")
        
        should have_selector("h3", text: "Niveau 1")
        should have_selector("h3", text: "Niveau 2")
        should have_selector("h3", text: "Niveau 3")
        should have_selector("h3", text: "Niveau 4")
        should have_selector("h3", text: "Niveau 5")
        
        should have_selector("table", class: "greeny", text: online_problem.statement) # Level 1
        should have_content(online_problem.origin)
        should have_selector("table", class: "redy", text: online_problem_with_one_prerequisite.statement) # Level 2
        should have_no_content(online_problem_with_one_prerequisite.origin)
        should have_selector("table", class: "redy", text: online_problem_with_two_prerequisites.statement) # Level 5
        should have_no_content(online_problem_with_two_prerequisites.origin)
        should have_selector("table", class: "redy", text: "(Vous avez un brouillon enregistré pour ce problème.)")
        should have_no_selector("table", text: offline_problem.statement)
        should have_selector("table", class: "orangey", text: problem_in_online_virtualtest.statement)  # Level 2
        should have_no_content(problem_in_online_virtualtest.origin)
        should have_selector("table", class: "redy", text: problem_with_prerequisite_in_online_virtualtest.statement)  # Level 4
        should have_no_content(problem_with_prerequisite_in_online_virtualtest.origin)
        should have_no_selector("table", text: problem_in_offline_virtualtest.statement)
        
        should have_content("Chaque problème de niveau 1 vaut 15 points.")
        should have_content("Chaque problème de niveau 2 vaut 30 points.")
        should have_no_content("Chaque problème de niveau 3 vaut 45 points.")
        should have_content("Chaque problème de niveau 4 vaut 60 points.")
        should have_content("Chaque problème de niveau 5 vaut 75 points.")
        
        should have_no_content("Aucun problème de niveau 1 n'est disponible.")
        should have_no_content("Aucun problème de niveau 2 n'est disponible.")
        should have_content("Aucun problème de niveau 3 n'est disponible.")
        should have_no_content("Aucun problème de niveau 4 n'est disponible.")
        should have_no_content("Aucun problème de niveau 5 n'est disponible.")
      end
    end
  end
  
  describe "admin" do
    before { sign_in_view(admin) }

    it "renders the expected problems" do
      render template: "problems/index"
      should have_selector("h1", text: section.name)
      should have_no_selector("div", text: "Les problèmes ne sont accessibles qu'aux utilisateurs ayant un score d'au moins 200.")
      
      should have_selector("h3", text: "Niveau 1")
      should have_selector("h3", text: "Niveau 2")
      should have_selector("h3", text: "Niveau 3")
      should have_selector("h3", text: "Niveau 4")
      should have_selector("h3", text: "Niveau 5")
      
      should have_selector("table", class: "yellowy", text: online_problem.statement)
      should have_content(online_problem.origin)
      should have_selector("table", class: "yellowy", text: online_problem_with_one_prerequisite.statement)
      should have_content(online_problem_with_one_prerequisite.origin)
      should have_selector("table", class: "yellowy", text: online_problem_with_two_prerequisites.statement)
      should have_content(online_problem_with_two_prerequisites.origin)
      should have_selector("table", class: "orangey", text: offline_problem.statement)
      should have_content(offline_problem.origin)
      should have_selector("table", class: "yellowy", text: problem_in_online_virtualtest.statement)
      should have_content(problem_in_online_virtualtest.origin)
      should have_selector("table", class: "yellowy", text: problem_with_prerequisite_in_online_virtualtest.statement)
      should have_content(problem_with_prerequisite_in_online_virtualtest.origin)
      should have_selector("table", class: "yellowy", text: problem_in_offline_virtualtest.statement)
      should have_content(problem_in_offline_virtualtest.origin)
      
      should have_content("Chaque problème de niveau 1 vaut 15 points.")
      should have_content("Chaque problème de niveau 2 vaut 30 points.")
      should have_content("Chaque problème de niveau 3 vaut 45 points.")
      should have_content("Chaque problème de niveau 4 vaut 60 points.")
      should have_content("Chaque problème de niveau 5 vaut 75 points.")
      
      should have_no_content("Aucun problème de niveau 1 n'est disponible.")
      should have_no_content("Aucun problème de niveau 2 n'est disponible.")
      should have_no_content("Aucun problème de niveau 3 n'est disponible.")
      should have_no_content("Aucun problème de niveau 4 n'est disponible.")
      should have_no_content("Aucun problème de niveau 5 n'est disponible.")
    end
  end
end
