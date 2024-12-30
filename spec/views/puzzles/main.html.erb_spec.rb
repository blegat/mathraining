# -*- coding: utf-8 -*-
require "spec_helper"

describe "puzzles/main.html.erb", type: :view, puzzle: true do

  subject { rendered }

  let(:admin) { FactoryGirl.create(:admin) }
  let(:root) { FactoryGirl.create(:root) }
  let!(:puzzle) { FactoryGirl.create(:puzzle, position: 1) }
  
  before { assign(:faqs, Faq.all) }
  
  context "if the user is not a root" do
    before { sign_in_view(admin) }
    
    context "and we are before the end date" do
      before { travel_to Puzzle.end_date - 10.minutes }
    
      it "renders the puzzles without the tabs" do
        render template: "puzzles/main"
        should have_no_link("Classement")
        expect(response).to render_template(:partial => "puzzles/_puzzles")
      end
      
      it "renders the puzzles without the tabs even if we try to show the rankings" do
        render template: "puzzles/main", locals: {params: {tab: 1}}
        expect(response).to render_template(:partial => "puzzles/_puzzles")
        expect(response).not_to render_template(:partial => "puzzles/_ranking")
      end
    end
    
    context "and we are after the end date" do
      before { travel_to Puzzle.end_date + 10.minutes }
    
      it "renders the puzzles with the tabs" do
        render template: "puzzles/main"
        should have_link("Classement")
        expect(response).to render_template(:partial => "puzzles/_puzzles")
      end
      
      it "renders the ranking if requested" do
        render template: "puzzles/main", locals: {params: {tab: 1}}
        expect(response).to render_template(:partial => "puzzles/_ranking")
      end
    end
  end
  
  context "if the user is a root" do
    before { sign_in_view(root) }
    
    context "and we are before the end date" do
      before { travel_to Puzzle.end_date - 10.minutes }
    
      it "renders the puzzles with the tabs" do
        render template: "puzzles/main"
        should have_link("Classement")
        expect(response).to render_template(:partial => "puzzles/_puzzles")
      end
      
      it "renders the ranking if requested" do
        render template: "puzzles/main", locals: {params: {tab: 1}}
        expect(response).to render_template(:partial => "puzzles/_ranking")
      end
    end
  end
end
