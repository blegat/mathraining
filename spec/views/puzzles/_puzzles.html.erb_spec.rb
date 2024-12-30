# -*- coding: utf-8 -*-
require "spec_helper"

describe "puzzles/_puzzles.html.erb", type: :view, puzzle: true do

  subject { rendered }

  let(:admin) { FactoryGirl.create(:admin) }
  let(:root) { FactoryGirl.create(:root) }
  let!(:puzzle) { FactoryGirl.create(:puzzle) }
    
  context "if the user is not a root" do
    before { sign_in_view(admin) }
    
    context "and we are before the end date" do
      before { travel_to Puzzle.end_date - 10.minutes }
  
      it "shows the form but not the solution" do
        render partial: "puzzles/puzzles"
        should have_selector("input", id: "code-#{puzzle.id}")
        should have_no_content(puzzle.code)
        should have_no_content(puzzle.explanation)
      end
    end
    
    context "and we are after the end date" do
      before { travel_to Puzzle.end_date + 10.minutes }
  
      it "shows the solution but not the form" do
        render partial: "puzzles/puzzles"
        should have_no_selector("input", id: "code-#{puzzle.id}")
        should have_content(puzzle.explanation)
      end
    end
  end
end
