# -*- coding: utf-8 -*-
require "spec_helper"

describe "questions/_admin.html.erb", type: :view, question: true do

  subject { rendered }

  let(:admin) { FactoryGirl.create(:admin) }
  let(:chapter) { FactoryGirl.create(:chapter, online: true) }
  let(:question) { FactoryGirl.create(:question, chapter: chapter, position: 2) }
  
  before do
    sign_in_view(admin)
    assign(:chapter, chapter)
  end
  
  context "if the question is an exercise and not online" do
    before { question.update(:online => false, :is_qcm => false, :explanation => "") }
      
    it "renders the correct options" do
      render partial: "questions/admin", locals: {question: question}
      should have_link("Modifier cet exercice")
      should have_no_link("Modifier les réponses") # qcm only
      should have_link("Modifier l'explication")
      should have_link("Supprimer cet exercice")
      should have_no_text("Déplacer cet exercice")
      should have_link("Mettre en ligne")
    end
  end
  
  context "if the question is a qcm and online" do
    let!(:question_before) { FactoryGirl.create(:question, chapter: chapter, position: 1, online: true) }
    before { question.update(:online => true, :is_qcm => true) }
      
    it "renders the correct options" do
      render partial: "questions/admin", locals: {question: question}
      should have_link("Modifier cet exercice")
      should have_link("Modifier les réponses")
      should have_link("Modifier l'explication")
      should have_no_link("Supprimer cet exercice") # because online
      should have_text("Déplacer cet exercice")
      should have_link("haut", :href => order_question_path(question, :new_position => 1))
      should have_no_link("bas")
      should have_no_link("Mettre en ligne") # because online
    end
    
    context "and also has a question after" do
      let!(:question_after) { FactoryGirl.create(:question, chapter: chapter, position: 4, online: false) }
      
      it "renders the link 'bas' too" do
        render partial: "questions/admin", locals: {question: question}
        should have_text("Déplacer cet exercice")
        should have_link("haut", :href => order_question_path(question, :new_position => 1))
        should have_link("bas", :href => order_question_path(question, :new_position => 4))
      end
    end
  end
end
