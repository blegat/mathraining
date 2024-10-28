# -*- coding: utf-8 -*-
require "spec_helper"

describe "chapters/_before.html.erb", type: :view, chapter: true do

  subject { rendered }

  let(:admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }
  let(:user_bad) { FactoryGirl.create(:user) }
  let!(:chapter_prerequisite) { FactoryGirl.create(:chapter, online: true) }
  let!(:chapter) { FactoryGirl.create(:chapter, online: true) }
  let!(:theory1) { FactoryGirl.create(:theory, chapter: chapter, online: true, position: 1) }
  let!(:theory2_offline) { FactoryGirl.create(:theory, chapter: chapter, online: false, position: 2) }
  let!(:theory3) { FactoryGirl.create(:theory, chapter: chapter, online: true, position: 3) }
  let!(:question1_offline) { FactoryGirl.create(:exercise, chapter: chapter, online: false, position: 1) }
  let!(:question2) { FactoryGirl.create(:exercise_decimal, chapter: chapter, online: true, position: 2) }
  let!(:question3) { FactoryGirl.create(:qcm, chapter: chapter, online: true, position: 4) }
  let!(:question4) { FactoryGirl.create(:qcm_multiple, chapter: chapter, online: true, position: 5) }
  let!(:sq3) { FactoryGirl.create(:solvedquestion, user: user, question: question3) }
  let!(:sq4) { FactoryGirl.create(:unsolvedquestion, user: user, question: question4) }
  
  before do
    user.theories << theory3
    assign(:section, chapter.section)
    assign(:chapter, chapter)
  end
  
  context "if chapter has a prerequisite" do
    before do
      chapter.prerequisites << chapter_prerequisite
      user.chapters << chapter_prerequisite
    end
    
    context "if the user is an admin" do
      before do
        assign(:current_user, admin)
        assign(:admin_or_user_writing_chapter, true)
        assign(:user_can_see_exercises, true)
      end
        
      it "renders the menu correctly" do
        render partial: "chapters/before"
        should have_selector("h5", text: "Général")
        should have_link("Résumé", href: chapter_path(chapter))
        should have_link("Chapitre entier", href: all_chapter_path(chapter))
        should have_link("Forum", href: subjects_path(:q => "cha-" + chapter.id.to_s))
        should have_selector("h5", text: "Points théoriques")
        should have_link(theory1.title, href: chapter_theory_path(chapter, theory1.id))
        should have_link(theory2_offline.title, href: chapter_theory_path(chapter, theory2_offline.id), class: "list-group-item-warning")
        should have_link(theory3.title, href: chapter_theory_path(chapter, theory3.id))
        should have_selector("h5", text: "Exercices")
        should have_link("Exercice", href: chapter_question_path(chapter, question1_offline.id), class: "list-group-item-warning")
        should have_link("Exercice 1", href: chapter_question_path(chapter, question2.id))
        should have_link("Exercice 2", href: chapter_question_path(chapter, question3.id))
        should have_link("Exercice 3", href: chapter_question_path(chapter, question4.id))
      end
      
      it "renders the menu for full chapter correctly" do
        render partial: "chapters/before", locals: {active: 'all'}
        should have_link("Chapitre entier", href: all_chapter_path(chapter), class: "active")
      end
      
      it "renders an online theory correctly" do
        render partial: "chapters/before", locals: {active: 'theory-' + theory1.id.to_s}
        should have_link(theory1.title, href: chapter_theory_path(chapter, theory1.id), class: "active")
      end
      
      it "renders an offline theory correctly" do
        render partial: "chapters/before", locals: {active: 'theory-' + theory2_offline.id.to_s}
        should have_link(theory2_offline.title, href: chapter_theory_path(chapter, theory2_offline.id), class: "active")
      end
      
      it "renders an online question correctly" do
        render partial: "chapters/before", locals: {active: 'question-' + question2.id.to_s}
        should have_link("Exercice 1", href: chapter_question_path(chapter, question2.id), class: "active")
      end
      
      it "renders an offline question correctly" do
        render partial: "chapters/before", locals: {active: 'question-' + question1_offline.id.to_s}
        should have_link("Exercice", href: chapter_question_path(chapter, question1_offline.id), class: "active")
      end
    end
    
    context "if the user has solved prerequisites" do
      before do
        assign(:current_user, user)
        assign(:admin_or_user_writing_chapter, false)
        assign(:user_can_see_exercises, true)
      end
      
      it "renders the menu correctly" do
        render partial: "chapters/before"
        should have_selector("h5", text: "Général")
        should have_link("Résumé", href: chapter_path(chapter))
        should have_link("Chapitre entier", href: all_chapter_path(chapter))
        should have_link("Forum", href: subjects_path(:q => "cha-" + chapter.id.to_s))
        should have_selector("h5", text: "Points théoriques")
        should have_link(theory1.title, href: chapter_theory_path(chapter, theory1.id))
        should have_no_link(theory2_offline.title, href: chapter_theory_path(chapter, theory2_offline.id))
        should have_link(theory3.title, href: chapter_theory_path(chapter, theory3.id), class: "list-group-item-success")
        should have_selector("h5", text: "Exercices")
        should have_no_link("Exercice", href: chapter_question_path(chapter, question1_offline.id))
        should have_link("Exercice 1", href: chapter_question_path(chapter, question2.id))
        should have_link("Exercice 2", href: chapter_question_path(chapter, question3.id), class: "list-group-item-success")
        should have_link("Exercice 3", href: chapter_question_path(chapter, question4.id), class: "list-group-item-danger")
      end
    end
    
    context "if the user has not solved prerequisites" do
      before do
        assign(:current_user, user_bad)
        assign(:admin_or_user_writing_chapter, false)
        assign(:user_can_see_exercises, false)
      end
      
      it "renders the menu correctly" do
        render partial: "chapters/before"
        should have_selector("h5", text: "Général")
        should have_link("Résumé", href: chapter_path(chapter))
        should have_link("Chapitre entier", href: all_chapter_path(chapter))
        should have_link("Forum", href: subjects_path(:q => "cha-" + chapter.id.to_s))
        should have_selector("h5", text: "Points théoriques")
        should have_link(theory1.title, href: chapter_theory_path(chapter, theory1.id))
        should have_no_link(theory2_offline.title, href: chapter_theory_path(chapter, theory2_offline.id))
        should have_link(theory3.title, href: chapter_theory_path(chapter, theory3.id))
        should have_selector("h5", text: "Exercices")
        should have_link("Exercice 1", href: "#", class: "disabled")
        should have_link("Exercice 2", href: "#", class: "disabled")
        should have_link("Exercice 3", href: "#", class: "disabled")
      end
    end
    
    context "if the user is not signed in" do
      before do
        assign(:admin_or_user_writing_chapter, false)
        assign(:user_can_see_exercises, false)
      end
      
      it "renders the menu correctly" do
        render partial: "chapters/before"
        should have_selector("h5", text: "Général")
        should have_link("Résumé", href: chapter_path(chapter))
        should have_link("Chapitre entier", href: all_chapter_path(chapter))
        should have_no_link("Forum", href: subjects_path(:q => "cha-" + chapter.id.to_s))
        should have_selector("h5", text: "Points théoriques")
        should have_link(theory1.title, href: chapter_theory_path(chapter, theory1.id))
        should have_no_link(theory2_offline.title, href: chapter_theory_path(chapter, theory2_offline.id))
        should have_link(theory3.title, href: chapter_theory_path(chapter, theory3.id))
        should have_selector("h5", text: "Exercices")
        should have_link("Exercice 1", href: "#", class: "disabled")
        should have_link("Exercice 2", href: "#", class: "disabled")
        should have_link("Exercice 3", href: "#", class: "disabled")
      end
    end
  end
  
  context "if the chapter has no prerequisite" do
    context "if the user is not signed in" do
      before do
        assign(:admin_or_user_writing_chapter, false)
        assign(:user_can_see_exercises, true)
      end
      
      it "renders the menu correctly" do
        render partial: "chapters/before"
        should have_no_link("Exercice", href: chapter_question_path(chapter, question1_offline.id))
        should have_link("Exercice 1", href: chapter_question_path(chapter, question2.id))
        should have_link("Exercice 2", href: chapter_question_path(chapter, question3.id))
        should have_link("Exercice 3", href: chapter_question_path(chapter, question4.id))
      end
    end
  end
end
