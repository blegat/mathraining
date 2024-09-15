# -*- coding: utf-8 -*-
require "spec_helper"

describe "chapters/show.html.erb", type: :view, chapter: true do

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
        assign(:signed_in, true)
        assign(:current_user, admin)
      end
        
      it "renders the menu correctly" do
        render template: "chapters/show"
        expect(rendered).to have_selector("h5", text: "Général")
        expect(rendered).to have_link("Résumé", href: chapter_path(chapter))
        expect(rendered).to have_link("Chapitre entier", href: chapter_path(chapter, :type => 10))
        expect(rendered).to have_link("Forum", href: subjects_path(:q => "cha-" + chapter.id.to_s))
        expect(rendered).to have_selector("h5", text: "Points théoriques")
        expect(rendered).to have_link(theory1.title, href: chapter_path(chapter, :type => 1, :which => theory1.id))
        expect(rendered).to have_link(theory2_offline.title, href: chapter_path(chapter, :type => 1, :which => theory2_offline.id), class: "list-group-item-warning")
        expect(rendered).to have_link(theory3.title, href: chapter_path(chapter, :type => 1, :which => theory3.id))
        expect(rendered).to have_selector("h5", text: "Exercices")
        expect(rendered).to have_link("Exercice", href: chapter_path(chapter, :type => 5, :which => question1_offline.id), class: "list-group-item-warning")
        expect(rendered).to have_link("Exercice 1", href: chapter_path(chapter, :type => 5, :which => question2.id))
        expect(rendered).to have_link("Exercice 2", href: chapter_path(chapter, :type => 5, :which => question3.id))
        expect(rendered).to have_link("Exercice 3", href: chapter_path(chapter, :type => 5, :which => question4.id))
        expect(response).to render_template(:partial => "_intro", :locals => {allow_edit: true})
      end
      
      it "renders the full chapter correctly" do
        render template: "chapters/show", locals: {params: {type: 10}}
        expect(rendered).to have_link("Chapitre entier", href: chapter_path(chapter, :type => 10), class: "active")
        expect(response).to render_template(:partial => "_all")
      end
      
      it "renders an online theory correctly" do
        render template: "chapters/show", locals: {params: {type: 1, which: theory1.id}}
        expect(rendered).to have_link(theory1.title, href: chapter_path(chapter, :type => 1, :which => theory1.id), class: "active")
        expect(response).to render_template(:partial => "theories/_show", :locals => {theory: theory1})
      end
      
      it "renders an offline theory correctly" do
        render template: "chapters/show", locals: {params: {type: 1, which: theory2_offline.id}}
        expect(rendered).to have_link(theory2_offline.title, href: chapter_path(chapter, :type => 1, :which => theory2_offline.id), class: "active")
        expect(response).to render_template(:partial => "theories/_show", :locals => {theory: theory2_offline})
      end
      
      it "renders an online question correctly" do
        render template: "chapters/show", locals: {params: {type: 5, which: question2.id}}
        expect(rendered).to have_link("Exercice 1", href: chapter_path(chapter, :type => 5, :which => question2.id), class: "active")
        expect(response).to render_template(:partial => "questions/_show", :locals => {question: question2})
      end
      
      it "renders an offline question correctly" do
        render template: "chapters/show", locals: {params: {type: 5, which: question1_offline.id}}
        expect(rendered).to have_link("Exercice", href: chapter_path(chapter, :type => 5, :which => question1_offline.id), class: "active")
        expect(response).to render_template(:partial => "questions/_show", :locals => {question: question1_offline})
      end
    end
    
    context "if the user has solved prerequisites" do
      before do
        assign(:signed_in, true)
        assign(:current_user, user)
      end
      
      it "renders the menu correctly" do
        render template: "chapters/show"
        expect(rendered).to have_selector("h5", text: "Général")
        expect(rendered).to have_link("Résumé", href: chapter_path(chapter))
        expect(rendered).to have_link("Chapitre entier", href: chapter_path(chapter, :type => 10))
        expect(rendered).to have_link("Forum", href: subjects_path(:q => "cha-" + chapter.id.to_s))
        expect(rendered).to have_selector("h5", text: "Points théoriques")
        expect(rendered).to have_link(theory1.title, href: chapter_path(chapter, :type => 1, :which => theory1.id))
        expect(rendered).to have_no_link(theory2_offline.title, href: chapter_path(chapter, :type => 1, :which => theory2_offline.id))
        expect(rendered).to have_link(theory3.title, href: chapter_path(chapter, :type => 1, :which => theory3.id), class: "list-group-item-success")
        expect(rendered).to have_selector("h5", text: "Exercices")
        expect(rendered).to have_no_link("Exercice", href: chapter_path(chapter, :type => 5, :which => question1_offline.id))
        expect(rendered).to have_link("Exercice 1", href: chapter_path(chapter, :type => 5, :which => question2.id))
        expect(rendered).to have_link("Exercice 2", href: chapter_path(chapter, :type => 5, :which => question3.id), class: "list-group-item-success")
        expect(rendered).to have_link("Exercice 3", href: chapter_path(chapter, :type => 5, :which => question4.id), class: "list-group-item-danger")
        
        expect(response).to render_template(:partial => "_intro", :locals => {allow_edit: true})
      end
      
      it "renders the full chapter correctly" do
        render template: "chapters/show", locals: {params: {type: 10}}
        expect(rendered).to have_link("Chapitre entier", href: chapter_path(chapter, :type => 10), class: "active")
        expect(response).to render_template(:partial => "_all")
      end
      
      it "renders an online theory correctly" do
        render template: "chapters/show", locals: {params: {type: 1, which: theory1.id}}
        expect(rendered).to have_link(theory1.title, href: chapter_path(chapter, :type => 1, :which => theory1.id), class: "active")
        expect(response).to render_template(:partial => "theories/_show", :locals => {theory: theory1})
      end
      
      it "does not render an offline theory" do
        render template: "chapters/show", locals: {params: {type: 1, which: theory2_offline.id}}
        expect(response).not_to render_template(:partial => "theories/_show", :locals => {theory: theory2_offline})
      end
      
      it "renders an online question correctly" do
        render template: "chapters/show", locals: {params: {type: 5, which: question2.id}}
        expect(rendered).to have_link("Exercice 1", href: chapter_path(chapter, :type => 5, :which => question2.id), class: "active")
        expect(response).to render_template(:partial => "questions/_show", :locals => {question: question2})
      end
      
      it "does not render an offline question" do
        render template: "chapters/show", locals: {params: {type: 5, which: question1_offline.id}}
        expect(response).not_to render_template(:partial => "questions/_show", :locals => {question: question1_offline})
      end
    end
    
    context "if the user has not solved prerequisites" do
      before do
        assign(:signed_in, true)
        assign(:current_user, user_bad)
      end
      
      it "renders the menu correctly" do
        render template: "chapters/show"
        expect(rendered).to have_selector("h5", text: "Général")
        expect(rendered).to have_link("Résumé", href: chapter_path(chapter))
        expect(rendered).to have_link("Chapitre entier", href: chapter_path(chapter, :type => 10))
        expect(rendered).to have_link("Forum", href: subjects_path(:q => "cha-" + chapter.id.to_s))
        expect(rendered).to have_selector("h5", text: "Points théoriques")
        expect(rendered).to have_link(theory1.title, href: chapter_path(chapter, :type => 1, :which => theory1.id))
        expect(rendered).to have_no_link(theory2_offline.title, href: chapter_path(chapter, :type => 1, :which => theory2_offline.id))
        expect(rendered).to have_link(theory3.title, href: chapter_path(chapter, :type => 1, :which => theory3.id))
        expect(rendered).to have_selector("h5", text: "Exercices")
        expect(rendered).to have_link("Exercice 1", href: "#", class: "disabled")
        expect(rendered).to have_link("Exercice 2", href: "#", class: "disabled")
        expect(rendered).to have_link("Exercice 3", href: "#", class: "disabled")
        
        expect(response).to render_template(:partial => "_intro", :locals => {allow_edit: true})
      end
      
      it "renders the full chapter correctly" do
        render template: "chapters/show", locals: {params: {type: 10}}
        expect(rendered).to have_link("Chapitre entier", href: chapter_path(chapter, :type => 10), class: "active")
        expect(response).to render_template(:partial => "_all")
      end
      
      it "renders an online theory correctly" do
        render template: "chapters/show", locals: {params: {type: 1, which: theory1.id}}
        expect(rendered).to have_link(theory1.title, href: chapter_path(chapter, :type => 1, :which => theory1.id), class: "active")
        expect(response).to render_template(:partial => "theories/_show", :locals => {theory: theory1})
      end
      
      it "does not render an online question" do
        render template: "chapters/show", locals: {params: {type: 5, which: question2.id}}
        expect(response).not_to render_template(:partial => "questions/_show", :locals => {question: question2})
      end
    end
    
    context "if the user is not signed in" do
      before do
        assign(:signed_in, false)
      end
      
      it "renders the menu correctly" do
        render template: "chapters/show"
        expect(rendered).to have_selector("h5", text: "Général")
        expect(rendered).to have_link("Résumé", href: chapter_path(chapter))
        expect(rendered).to have_link("Chapitre entier", href: chapter_path(chapter, :type => 10))
        expect(rendered).to have_no_link("Forum", href: subjects_path(:q => "cha-" + chapter.id.to_s))
        expect(rendered).to have_selector("h5", text: "Points théoriques")
        expect(rendered).to have_link(theory1.title, href: chapter_path(chapter, :type => 1, :which => theory1.id))
        expect(rendered).to have_no_link(theory2_offline.title, href: chapter_path(chapter, :type => 1, :which => theory2_offline.id))
        expect(rendered).to have_link(theory3.title, href: chapter_path(chapter, :type => 1, :which => theory3.id))
        expect(rendered).to have_selector("h5", text: "Exercices")
        expect(rendered).to have_link("Exercice 1", href: "#", class: "disabled")
        expect(rendered).to have_link("Exercice 2", href: "#", class: "disabled")
        expect(rendered).to have_link("Exercice 3", href: "#", class: "disabled")
        
        expect(response).to render_template(:partial => "_intro", :locals => {allow_edit: true})
      end
      
      it "renders the full chapter correctly" do
        render template: "chapters/show", locals: {params: {type: 10}}
        expect(rendered).to have_link("Chapitre entier", href: chapter_path(chapter, :type => 10), class: "active")
        expect(response).to render_template(:partial => "_all")
      end
      
      it "renders an online theory correctly" do
        render template: "chapters/show", locals: {params: {type: 1, which: theory1.id}}
        expect(rendered).to have_link(theory1.title, href: chapter_path(chapter, :type => 1, :which => theory1.id), class: "active")
        expect(response).to render_template(:partial => "theories/_show", :locals => {theory: theory1})
      end
      
      it "does not render an online question" do
        render template: "chapters/show", locals: {params: {type: 5, which: question2.id}}
        expect(response).not_to render_template(:partial => "questions/_show", :locals => {question: question2})
      end
    end
  end
  
  context "if the chapter has no prerequisite" do
    context "if the user is not signed in" do
      before do
        assign(:signed_in, false)
      end
      
      it "renders the menu correctly" do
        render template: "chapters/show"
        expect(rendered).to have_no_link("Exercice", href: chapter_path(chapter, :type => 5, :which => question1_offline.id))
        expect(rendered).to have_link("Exercice 1", href: chapter_path(chapter, :type => 5, :which => question2.id))
        expect(rendered).to have_link("Exercice 2", href: chapter_path(chapter, :type => 5, :which => question3.id))
        expect(rendered).to have_link("Exercice 3", href: chapter_path(chapter, :type => 5, :which => question4.id))
        
        expect(response).to render_template(:partial => "_intro", :locals => {allow_edit: true})
      end
      
      it "renders an online question correctly" do
        render template: "chapters/show", locals: {params: {type: 5, which: question2.id}}
        expect(rendered).to have_link("Exercice 1", href: chapter_path(chapter, :type => 5, :which => question2.id), class: "active")
        expect(response).to render_template(:partial => "questions/_show", :locals => {question: question2})
      end
    end
  end
end
