# -*- coding: utf-8 -*-
require "spec_helper"

describe "contestsolutions/_index.html.erb", type: :view, contestsolution: true do

  subject { rendered }

  let(:contest) { FactoryBot.create(:contest, status: :in_progress) }
  let(:contestproblem1_corrected) { FactoryBot.create(:contestproblem, contest: contest, status: :corrected) }
  let(:contestproblem2_in_correction) { FactoryBot.create(:contestproblem, contest: contest, status: :in_correction) }
  
  let(:organizer) { FactoryBot.create(:user) }
  let(:user1) { FactoryBot.create(:user) }
  let(:user2) { FactoryBot.create(:user) }
  let(:user3) { FactoryBot.create(:user) }
  let(:user4) { FactoryBot.create(:user) }
  
  let!(:contestsolution11) { FactoryBot.create(:contestsolution, contestproblem: contestproblem1_corrected, user: user1, corrected: true, score: 7, star: true) }
  let!(:contestsolution12) { FactoryBot.create(:contestsolution, contestproblem: contestproblem1_corrected, user: user2, corrected: true, score: 7) }
  let!(:contestsolution13) { FactoryBot.create(:contestsolution, contestproblem: contestproblem1_corrected, user: user3, corrected: true, score: 3) }
  let!(:contestsolution1_official) { contestproblem1_corrected.contestsolutions.where(:official => true).first }
  
  let!(:contestsolution21) { FactoryBot.create(:contestsolution, contestproblem: contestproblem2_in_correction, user: user1, corrected: true, score: 7, star: true) }
  let!(:contestsolution22) { FactoryBot.create(:contestsolution, contestproblem: contestproblem2_in_correction, user: user2, corrected: true, score: 7) }
  let!(:contestsolution23) { FactoryBot.create(:contestsolution, contestproblem: contestproblem2_in_correction, user: user3, corrected: true, score: 3) }
  let!(:contestsolution24) { FactoryBot.create(:contestsolution, contestproblem: contestproblem2_in_correction, user: user4, corrected: false, score: -1) }
  let!(:contestsolution2_official) { contestproblem2_in_correction.contestsolutions.where(:official => true).first }
  
  before do
    contest.organizers << organizer
    assign(:contest, contest)
  end
  
  context "if user is an organizer" do
    before { sign_in_view(organizer) }
    
    context "and problem has been corrected" do
      before { assign(:contestproblem, contestproblem1_corrected) }
      
      it "renders the solutions correctly" do
        render partial: "contestsolutions/index"
        should have_no_selector("h3", text: "Votre solution")
        should have_selector("h3", text: "Solutions étoilées")
        should have_selector("h3", text: "Autres solutions correctes")
        should have_selector("h3", text: "Solutions erronées / non-publiques")
        should have_no_selector("h3", text: "Solutions à corriger")
        expect(response).to render_template(:partial => "contestsolutions/_line", :locals => {sol: contestsolution11, type: "starred"})
        expect(response).to render_template(:partial => "contestsolutions/_line", :locals => {sol: contestsolution12, type: "good"})
        expect(response).to render_template(:partial => "contestsolutions/_line", :locals => {sol: contestsolution13, type: "bad"})
        expect(response).to render_template(:partial => "contestsolutions/_line", :locals => {sol: contestsolution1_official, type: "bad"})
      end
      
      context "but there is only the official solution" do
        before do
          contestsolution11.destroy
          contestsolution12.destroy
          contestsolution13.destroy
          contestsolution1_official.update(:score => 7, :star => true)
        end
        
        it "renders the solutions correctly" do
          render partial: "contestsolutions/index"
          should have_no_selector("h3", text: "Votre solution")
          should have_selector("h3", text: "Solutions étoilées")
          should have_selector("h3", text: "Autres solutions correctes")
          should have_content("Aucune autre solution correcte")
          should have_selector("h3", text: "Solutions erronées / non-publiques")
          should have_content("Aucune solution erronée.")
          should have_no_selector("h3", text: "Solutions à corriger")
          expect(response).to render_template(:partial => "contestsolutions/_line", :locals => {sol: contestsolution1_official, type: "starred"})
        end
      end
    end
    
    context "and problem is still in correction" do
      before { assign(:contestproblem, contestproblem2_in_correction) }
      
      it "renders the solutions correctly" do
        render partial: "contestsolutions/index"
        should have_no_selector("h3", text: "Votre solution")
        should have_selector("h3", text: "Solutions étoilées")
        should have_selector("h3", text: "Autres solutions correctes")
        should have_selector("h3", text: "Solutions erronées / non-publiques")
        should have_selector("h3", text: "Solutions à corriger")
        should have_no_link("Publier les résultats")
        expect(response).to render_template(:partial => "contestsolutions/_line", :locals => {sol: contestsolution21, type: "starred"})
        expect(response).to render_template(:partial => "contestsolutions/_line", :locals => {sol: contestsolution22, type: "good"})
        expect(response).to render_template(:partial => "contestsolutions/_line", :locals => {sol: contestsolution23, type: "bad"})
        expect(response).to render_template(:partial => "contestsolutions/_line", :locals => {sol: contestsolution24, type: "tocorrect"})
        expect(response).to render_template(:partial => "contestsolutions/_line", :locals => {sol: contestsolution2_official, type: "bad"})
      end
      
      context "and all solutions are corrected" do
        before { contestsolution24.update(:corrected => true, :score => 0) }
        
        it "renders the publish button" do
          render partial: "contestsolutions/index"
          should have_link("Publier les résultats")
        end
        
        context "but there is no star solution" do
          before { contestsolution21.update(:star => false) }
          
          it "does not render the publish button" do
            render partial: "contestsolutions/index"
            should have_no_link("Publier les résultats")
            should have_content("Il faut au minimum une solution étoilée pour publier les résultats.")
          end
        end
      end
    end
  end
  
  context "if user is a student with star solution" do
    before { sign_in_view(user1) }
    
    context "and problem has been corrected" do
      before { assign(:contestproblem, contestproblem1_corrected) }
      
      it "renders the solutions correctly" do
        render partial: "contestsolutions/index"
        should have_selector("h3", text: "Votre solution")
        should have_selector("h3", text: "Autres solutions étoilées")
        should have_content("Aucune autre solution étoilée.")
        should have_selector("h3", text: "Autres solutions correctes")
        should have_no_selector("h3", text: "Solutions erronées / non-publiques")
        should have_no_selector("h3", text: "Solutions à corriger")
        expect(response).to render_template(:partial => "contestsolutions/_line", :locals => {sol: contestsolution11, type: "mine"})
        expect(response).to render_template(:partial => "contestsolutions/_line", :locals => {sol: contestsolution12, type: "good"})
        expect(response).not_to render_template(:partial => "contestsolutions/_line", :locals => {sol: contestsolution13, type: "bad"})
        expect(response).not_to render_template(:partial => "contestsolutions/_line", :locals => {sol: contestsolution1_official, type: "bad"})
      end
    end
    
    context "and problem is still in correction" do
      before { assign(:contestproblem, contestproblem2_in_correction) }
      
      it "renders the solutions correctly" do
        render partial: "contestsolutions/index"
        should have_selector("h3", text: "Votre solution")
        should have_no_selector("h3", text: "Solutions étoilées")
        should have_no_selector("h3", text: "Autres solutions correctes")
        should have_no_selector("h3", text: "Solutions erronées / non-publiques")
        should have_no_selector("h3", text: "Solutions à corriger")
        expect(response).to render_template(:partial => "contestsolutions/_line", :locals => {sol: contestsolution21, type: "mine"})
        expect(response).not_to render_template(:partial => "contestsolutions/_line", :locals => {sol: contestsolution22, type: "good"})
        expect(response).not_to render_template(:partial => "contestsolutions/_line", :locals => {sol: contestsolution23, type: "bad"})
        expect(response).not_to render_template(:partial => "contestsolutions/_line", :locals => {sol: contestsolution24, type: "tocorrect"})
        expect(response).not_to render_template(:partial => "contestsolutions/_line", :locals => {sol: contestsolution2_official, type: "bad"})
      end
    end
  end
  
  context "if user is a student with good solution" do
    before { sign_in_view(user2) }
    
    context "and problem has been corrected" do
      before { assign(:contestproblem, contestproblem1_corrected) }
      
      it "renders the solutions correctly" do
        render partial: "contestsolutions/index"
        should have_selector("h3", text: "Votre solution")
        should have_selector("h3", text: "Solutions étoilées")
        should have_selector("h3", text: "Autres solutions correctes")
        should have_content("Aucune autre solution correcte.")
        should have_no_selector("h3", text: "Solutions erronées / non-publiques")
        should have_no_selector("h3", text: "Solutions à corriger")
        expect(response).to render_template(:partial => "contestsolutions/_line", :locals => {sol: contestsolution11, type: "starred"})
        expect(response).to render_template(:partial => "contestsolutions/_line", :locals => {sol: contestsolution12, type: "mine"})
        expect(response).not_to render_template(:partial => "contestsolutions/_line", :locals => {sol: contestsolution13, type: "bad"})
        expect(response).not_to render_template(:partial => "contestsolutions/_line", :locals => {sol: contestsolution1_official, type: "bad"})
      end
    end
    
    context "and problem is still in correction" do
      before { assign(:contestproblem, contestproblem2_in_correction) }
      
      it "renders the solutions correctly" do
        render partial: "contestsolutions/index"
        should have_selector("h3", text: "Votre solution")
        should have_no_selector("h3", text: "Solutions étoilées")
        should have_no_selector("h3", text: "Autres solutions correctes")
        should have_no_selector("h3", text: "Solutions erronées / non-publiques")
        should have_no_selector("h3", text: "Solutions à corriger")
        expect(response).not_to render_template(:partial => "contestsolutions/_line", :locals => {sol: contestsolution21, type: "starred"})
        expect(response).to render_template(:partial => "contestsolutions/_line", :locals => {sol: contestsolution22, type: "mine"})
        expect(response).not_to render_template(:partial => "contestsolutions/_line", :locals => {sol: contestsolution23, type: "bad"})
        expect(response).not_to render_template(:partial => "contestsolutions/_line", :locals => {sol: contestsolution24, type: "tocorrect"})
        expect(response).not_to render_template(:partial => "contestsolutions/_line", :locals => {sol: contestsolution2_official, type: "bad"})
      end
    end
  end
end
