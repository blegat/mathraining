# -*- coding: utf-8 -*-
require "spec_helper"

describe "questions/_answer.html.erb", type: :view, question: true do

  subject { rendered }

  let(:question) { FactoryBot.create(:question) }
  
  context "if the question is an exercise with integer answer" do
    before { question.update(:is_qcm => false, :decimal => false, :answer => 4321) }
      
    it "renders the answer correctly" do
      render partial: "questions/answer", locals: {question: question}
      should have_text("4321")
      should have_no_text("4321.0")
      should have_text("On attend un nombre entier")
    end
  end
  
  context "if the question is an exercise with decimal answer" do
    before { question.update(:is_qcm => false, :decimal => true, :answer => 4321.234) }
      
    it "renders the answer correctly" do
      render partial: "questions/answer", locals: {question: question}
      should have_text("4321.234")
      should have_text("On attend un nombre réel")
    end
  end
  
  context "if the question is an exercise with decimal answer that is actually integer" do
    before { question.update(:is_qcm => false, :decimal => true, :answer => 4321) }
      
    it "renders the answer correctly" do
      render partial: "questions/answer", locals: {question: question}
      should have_text("4321")
      should have_no_text("4321.0")
      should have_text("On attend un nombre réel")
    end
  end
  
  context "if the question is a qcm" do
    let!(:item1) { FactoryBot.create(:item, question: question, position: 1, ok: true) }
    let!(:item2) { FactoryBot.create(:item, question: question, position: 2, ok: false) }
    
    context "that has a single answer" do
      before { question.update(:is_qcm => true, :many_answers => false) }
      
      it "renders the items correctly" do
        render partial: "questions/answer", locals: {question: question}
        should have_text(item1.ans)
        should have_selector("img", :id => "v-#{item1.id}")
        should have_text(item2.ans)
        should have_no_selector("img", :id => "x-#{item2.id}") # X icon not shown when there is a single answer
      end
    end
    
    context "that has a single answer" do
      before { question.update(:is_qcm => true, :many_answers => true) }
      
      it "renders the items correctly" do
        render partial: "questions/answer", locals: {question: question}
        should have_text(item1.ans)
        should have_selector("img", :id => "v-#{item1.id}")
        should have_text(item2.ans)
        should have_selector("img", :id => "x-#{item2.id}")
      end
    end
  end
end
