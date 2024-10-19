# -*- coding: utf-8 -*-
require "spec_helper"

describe "corrections/_new.html.erb", type: :view, correction: true do

  let(:user) { FactoryGirl.create(:user) }
  let(:admin) { FactoryGirl.create(:user) }
  let(:submission) { FactoryGirl.create(:submission, user: user) }
  
  before do
    assign(:problem, submission.problem)
    assign(:submission, submission)
  end
  
  context "if the user is the submission owner" do
    before do
      assign(:current_user, user)
      assign(:correction, Correction.new)
    end
      
    it "renders only one button" do
      render partial: "corrections/new"
      expect(rendered).to have_button("Poster", :exact => true)
    end
  end
  
  context "if the user is not the submission owner" do
    before do
      assign(:current_user, admin)
      assign(:correction, Correction.new)
    end
    
    context "and the submission is waiting" do
      before do
        submission.waiting!
      end
      
      it "renders two buttons" do
        render partial: "corrections/new"
        expect(rendered).to have_no_field("score")
        expect(rendered).to have_no_button("Poster", :exact => true)
        expect(rendered).to have_button("Poster et refuser la soumission")
        expect(rendered).to have_button("Poster et accepter la soumission")
      end
      
      context "and the submission is in a test" do
        before do
          submission.update_attribute(:intest, true)
          submission.problem.update_attribute(:markscheme, "Voici le marking scheme")
        end
        
        it "renders the mark scheme" do
          render partial: "corrections/new"
          expect(rendered).to have_field("score")
          expect(rendered).to have_selector("h5", text: "Marking scheme")
          expect(rendered).to have_content(submission.problem.markscheme)
        end
      end
    end
    
    context "and the submission is correct" do
      before do
        submission.correct!
      end
      
      it "renders only one button" do
        render partial: "corrections/new"
        expect(rendered).to have_button("Poster", :exact => true)
      end
    end
    
    context "and the submission is wrong to read" do
      before do
        submission.wrong_to_read!
      end
      
      it "renders two buttons" do
        render partial: "corrections/new"
        expect(rendered).to have_no_button("Poster", :exact => true)
        expect(rendered).to have_button("Poster et laisser la soumission comme erronée")
        expect(rendered).to have_button("Poster et accepter la soumission")
      end
    end
    
    context "and the submission is wrong" do
      before do
        submission.wrong!
      end
      
      it "renders two buttons" do
        render partial: "corrections/new"
        expect(rendered).to have_button("Poster", :exact => true)
        expect(rendered).to have_button("Poster et accepter la soumission")
      end
    end
  end
end
