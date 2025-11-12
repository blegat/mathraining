# -*- coding: utf-8 -*-
require "spec_helper"

describe "contestsolutions/_line.html.erb", type: :view, contestsolution: true do

  subject { rendered }

  let(:contest) { FactoryBot.create(:contest, status: :in_progress) }
  let(:contestproblem) { FactoryBot.create(:contestproblem, contest: contest) }
  
  let(:organizer) { FactoryBot.create(:user) }
  let(:user) { FactoryBot.create(:user) }
  
  let(:contestsolution) { FactoryBot.create(:contestsolution, contestproblem: contestproblem, user: user) }
  
  before do
    contest.organizers << organizer
    assign(:contest, contest)
    assign(:contestproblem, contestproblem)
    assign(:contestsolution, contestsolution)
  end
  
  context "if the problem is in progress" do
    before { contestproblem.update_attribute(:status, :in_progress) }
  
    context "and user is an organizer" do
      before { sign_in_view(organizer) }
    
      context "and solution is official starred" do
        before { contestsolution.update(:official => true, :user_id => 0, :corrected => true, :score => 7, :star => true) }
        
        it do
          render template: "contestsolutions/show"
          should have_selector("h3", text: "Solution officielle (publique)", normalize_ws: true, exact_text: true)
          should have_content("Cliquez ici pour réserver")
          expect(response).to render_template(:partial => "contestproblems/_show")
          expect(response).not_to render_template(:partial => "shared/_post", :locals => {ms: contestsolution, kind: "contestsolution"})
          expect(response).not_to render_template(:partial => "contestsolutions/_edit", :locals => {contestsolution: contestsolution})
          expect(response).to render_template(:partial => "contestcorrections/_show", :locals => {contestsolution: contestsolution, contestcorrection: contestsolution.contestcorrection})
        end
      end
    end
  end
  
  context "if the problem is in correction" do
    before { contestproblem.update_attribute(:status, :in_correction) }
  
    context "and user is an organizer" do
      before { sign_in_view(organizer) }
    
      context "and solution is official starred" do
        before { contestsolution.update(:official => true, :user_id => 0, :corrected => true, :score => 7, :star => true) }
        
        it do
          render template: "contestsolutions/show"
          should have_selector("h3", text: "Solution officielle (publique)", normalize_ws: true, exact_text: true)
          should have_content("Cliquez ici pour réserver")
          expect(response).not_to render_template(:partial => "shared/_post", :locals => {ms: contestsolution, kind: "contestsolution"})
          expect(response).not_to render_template(:partial => "contestsolutions/_edit", :locals => {contestsolution: contestsolution})
          expect(response).to render_template(:partial => "contestcorrections/_show", :locals => {contestsolution: contestsolution, contestcorrection: contestsolution.contestcorrection})
        end
      end
      
      context "and solution is official non-public" do
        before { contestsolution.update(:official => true, :user_id => 0, :corrected => true, :score => 0) }
        
        it do
          render template: "contestsolutions/show"
          should have_selector("h3", text: "Solution officielle (non-publique)", normalize_ws: true, exact_text: true)
          should have_content("Cliquez ici pour réserver")
          expect(response).not_to render_template(:partial => "shared/_post", :locals => {ms: contestsolution, kind: "contestsolution"})
          expect(response).not_to render_template(:partial => "contestsolutions/_edit", :locals => {contestsolution: contestsolution})
          expect(response).to render_template(:partial => "contestcorrections/_show", :locals => {contestsolution: contestsolution, contestcorrection: contestsolution.contestcorrection})
        end
      end
      
      context "and solution is from a user, already corrected" do
        before { contestsolution.update(:official => false, :user => user, :corrected => true, :score => 5) }
        
        it do
          render template: "contestsolutions/show"
          should have_selector("h3", text: "Solution de #{user.name}", normalize_ws: true, exact_text: true)
          should have_content("Cliquez ici pour réserver")
          expect(response).to render_template(:partial => "shared/_post", :locals => {ms: contestsolution, kind: "contestsolution", can_edit: false})
          expect(response).not_to render_template(:partial => "contestsolutions/_edit", :locals => {contestsolution: contestsolution})
          expect(response).to render_template(:partial => "contestcorrections/_show", :locals => {contestsolution: contestsolution, contestcorrection: contestsolution.contestcorrection})
        end
      end
      
      context "and solution is from a user, not corrected yet" do
        before { contestsolution.update(:official => false, :user => user, :corrected => false, :score => -1) }
        
        it do
          render template: "contestsolutions/show"
          should have_selector("h3", text: "Solution de #{user.name} (à corriger)", normalize_ws: true, exact_text: true)
          should have_content("Cliquez ici pour réserver")
          expect(response).to render_template(:partial => "shared/_post", :locals => {ms: contestsolution, kind: "contestsolution", can_edit: false})
          expect(response).not_to render_template(:partial => "contestsolutions/_edit", :locals => {contestsolution: contestsolution})
          expect(response).to render_template(:partial => "contestcorrections/_show", :locals => {contestsolution: contestsolution, contestcorrection: contestsolution.contestcorrection})
        end
      end
    end
    
    context "and user is a contestant" do
      before { sign_in_view(user) }
    
      context "and solution is his solution" do
        before { contestsolution.update(:official => false, :user => user, :corrected => true, :score => 7, :star => true) }
        
        it do
          render template: "contestsolutions/show"
          should have_selector("h3", text: "Votre solution (en attente de correction)", normalize_ws: true, exact_text: true)
          should have_no_content("Cliquez ici pour réserver")
          expect(response).to render_template(:partial => "shared/_post", :locals => {ms: contestsolution, kind: "contestsolution", can_edit: false})
          expect(response).not_to render_template(:partial => "contestsolutions/_edit", :locals => {contestsolution: contestsolution})
          expect(response).not_to render_template(:partial => "contestcorrections/_show", :locals => {contestsolution: contestsolution, contestcorrection: contestsolution.contestcorrection})
        end
      end
    end
  end
  
  context "if the problem is corrected" do
    before { contestproblem.update_attribute(:status, :corrected) }
  
    context "and user is an organizer" do
      before { sign_in_view(organizer) }
      
      context "and solution is official non-public" do
        before { contestsolution.update(:official => true, :user_id => 0, :corrected => true, :score => 0) }
        
        it do
          render template: "contestsolutions/show"
          should have_selector("h3", text: "Solution officielle (non-publique)", normalize_ws: true, exact_text: true)
          should have_content("Cliquez ici pour réserver")
          expect(response).not_to render_template(:partial => "shared/_post", :locals => {ms: contestsolution, kind: "contestsolution"})
          expect(response).not_to render_template(:partial => "contestsolutions/_edit", :locals => {contestsolution: contestsolution})
          expect(response).to render_template(:partial => "contestcorrections/_show", :locals => {contestsolution: contestsolution, contestcorrection: contestsolution.contestcorrection})
        end
      end
      
      context "and solution is from a user" do
        before { contestsolution.update(:official => false, :user => user, :corrected => true, :score => 5) }
        
        it do
          render template: "contestsolutions/show"
          should have_selector("h3", text: "Solution de #{user.name}", normalize_ws: true, exact_text: true)
          should have_no_content("Cliquez ici pour réserver")
          expect(response).to render_template(:partial => "shared/_post", :locals => {ms: contestsolution, kind: "contestsolution", can_edit: false})
          expect(response).not_to render_template(:partial => "contestsolutions/_edit", :locals => {contestsolution: contestsolution})
          expect(response).to render_template(:partial => "contestcorrections/_show", :locals => {contestsolution: contestsolution, contestcorrection: contestsolution.contestcorrection})
        end
      end
    end
    
    context "and user is a contestant" do
      before { sign_in_view(user) }
    
      context "and solution is his solution" do
        before { contestsolution.update(:official => false, :user => user, :corrected => true, :score => 7, :star => true) }
        
        it do
          render template: "contestsolutions/show"
          should have_selector("h3", text: "Votre solution", normalize_ws: true, exact_text: true)
          should have_no_content("Cliquez ici pour réserver")
          expect(response).to render_template(:partial => "shared/_post", :locals => {ms: contestsolution, kind: "contestsolution", can_edit: false})
          expect(response).not_to render_template(:partial => "contestsolutions/_edit", :locals => {contestsolution: contestsolution})
          expect(response).to render_template(:partial => "contestcorrections/_show", :locals => {contestsolution: contestsolution, contestcorrection: contestsolution.contestcorrection})
        end
      end
      
      context "and solution is his solution" do
        let(:other_user) { FactoryBot.create(:user) }
        before { contestsolution.update(:official => false, :user => other_user, :corrected => true, :score => 7, :star => false) }
        
        it do
          render template: "contestsolutions/show"
          should have_selector("h3", text: "Solution de #{other_user.name}", normalize_ws: true, exact_text: true)
          should have_no_content("Cliquez ici pour réserver")
          expect(response).to render_template(:partial => "shared/_post", :locals => {ms: contestsolution, kind: "contestsolution", can_edit: false})
          expect(response).not_to render_template(:partial => "contestsolutions/_edit", :locals => {contestsolution: contestsolution})
          expect(response).to render_template(:partial => "contestcorrections/_show", :locals => {contestsolution: contestsolution, contestcorrection: contestsolution.contestcorrection})
        end
      end
    end
  end
end
