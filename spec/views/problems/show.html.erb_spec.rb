# -*- coding: utf-8 -*-
require "spec_helper"

describe "problems/show.html.erb", type: :view, problem: true do

  let(:admin) { FactoryGirl.create(:admin) }
  let(:bad_user) { FactoryGirl.create(:user, rating: 200) }
  let(:good_user) { FactoryGirl.create(:user, rating: 200) }
  let(:bad_corrector) { FactoryGirl.create(:user, corrector: true) }
  let(:good_corrector) { FactoryGirl.create(:user, corrector: true) }
  let(:chapter) { FactoryGirl.create(:chapter, online: true) }
  let!(:problem) { FactoryGirl.create(:problem, online: true, explanation: "Voici la solution") }
  let!(:offline_virtualtest) { FactoryGirl.create(:virtualtest, online: false) }
  let!(:user_submission) { FactoryGirl.create(:submission, user: good_user, problem: problem, status: :correct) }
  let!(:user_sp) { FactoryGirl.create(:solvedproblem, user: good_user, problem: problem, submission: user_submission) }
  let!(:corrector_submission) { FactoryGirl.create(:submission, user: good_corrector, problem: problem, status: :correct) }
  let!(:corrector_sp) { FactoryGirl.create(:solvedproblem, user: good_corrector, problem: problem, submission: corrector_submission) }
  
  before do
    assign(:problem, problem)
    problem.chapters << chapter
  end
  
  context "if the user is an admin" do
    before do
      assign(:signed_in, true)
      assign(:current_user, admin)
    end
    
    context "if the problem is offline" do
      before { problem.update(online: false) }
      
      it "renders the page correctly" do
        render template: "problems/show"
        expect(rendered).to have_text("Ce problème ne fait partie d'aucun test virtuel")
        expect(rendered).to have_text("Faire appartenir ce problème à")
        expect(rendered).to have_selector("h3", text: "Prérequis")
        expect(rendered).to have_link(chapter.name, href: chapter_path(chapter))
        expect(rendered).to have_link("Supprimer ce prérequis", href: problem_delete_prerequisite_path(problem, :chapter_id => chapter.id))
        expect(rendered).to have_text("Ajouter le prérequis :")
        expect(rendered).to have_text(problem.statement)
        expect(rendered).to have_text(problem.origin)
        expect(rendered).to have_link("Modifier ce problème")
        expect(rendered).to have_link("Modifier la solution")
        expect(rendered).to have_link("Modifier les solutions externes")
        expect(rendered).to have_link("Supprimer ce problème")
        expect(rendered).to have_button("Mettre en ligne")
        expect(response).not_to render_template(:partial => "submissions/_index", :locals => {problem: problem})
        expect(rendered).to have_button("Éléments de solution")
      end
    end
    
    context "if the problem is online" do      
      it "renders the page correctly" do
        render template: "problems/show"
        expect(rendered).not_to have_text("Ce problème ne fait partie d'aucun test virtuel")
        expect(rendered).not_to have_text("Faire appartenir ce problème à")
        expect(rendered).to have_selector("h3", text: "Prérequis")
        expect(rendered).to have_link(chapter.name, href: chapter_path(chapter))
        expect(rendered).not_to have_link("Supprimer ce prérequis", href: problem_delete_prerequisite_path(problem, :chapter_id => chapter.id))
        expect(rendered).not_to have_text("Ajouter le prérequis :")
        expect(rendered).to have_text(problem.statement)
        expect(rendered).to have_text(problem.origin)
        expect(rendered).to have_link("Modifier ce problème")
        expect(rendered).to have_link("Modifier la solution")
        expect(rendered).to have_link("Modifier les solutions externes")
        expect(rendered).not_to have_link("Supprimer ce problème")
        expect(rendered).not_to have_button("Mettre en ligne")
        expect(response).to render_template(:partial => "submissions/_index", :locals => {problem: problem})
        expect(rendered).to have_button("Éléments de solution")
      end
    end
  end
  
  context "if the user didn't solve the problem" do
    before do
      assign(:signed_in, true)
      assign(:current_user, bad_user)
    end
        
    it "renders the page correctly" do
      render template: "problems/show"
      expect(rendered).not_to have_text("Ce problème ne fait partie d'aucun test virtuel")
      expect(rendered).not_to have_selector("h3", text: "Prérequis")
      expect(rendered).to have_text(problem.statement)
      expect(rendered).not_to have_text(problem.origin)
      expect(rendered).not_to have_link("Modifier ce problème")
      expect(response).to render_template(:partial => "submissions/_index", :locals => {problem: problem})
      expect(rendered).to have_link("Nouvelle soumission")
      expect(rendered).not_to have_button("Éléments de solution")
    end
    
    context "and tries to write a new submission" do
      let!(:new_submission) { Submission.new }
      before { assign(:submission, new_submission) }
      
      it "renders the form correctly" do
        render template: "problems/show"
        expect(response).to render_template(:partial => "submissions/_new", :locals => {problem: problem, submission: new_submission})
      end
    end
    
    context "and tries to edit a draft" do
      let!(:draft_submission) { FactoryGirl.create(:submission, user: bad_user, status: :draft) }
      before { assign(:submission, draft_submission) }
      
      it "renders the form correctly" do
        render template: "problems/show"
        expect(response).to render_template(:partial => "submissions/_edit_draft", :locals => {problem: problem, submission: draft_submission})
      end
    end
    
    context "and tries to write a new submission without knowing LaTeX" do
      let!(:new_submission) { Submission.new }
      let!(:latex_chapter) { FactoryGirl.create(:chapter, online: true, submission_prerequisite: true) }
      before { assign(:submission, new_submission) }
      
      it "renders the message correctly" do
        render template: "problems/show"
        expect(response).not_to render_template(:partial => "submissions/_new")
        expect(response).to render_template(:partial => "submissions/_chapters_to_write_submission")
      end
    end
    
    context "and tries to see a submission of someone else" do
      before { assign(:submission, user_submission) }
      
      it "does not show the submission" do
        render template: "problems/show"
        expect(response).not_to render_template(:partial => "submissions/_show")
      end
    end
    
    context "and tries to see a his own submission" do
      let!(:wrong_submission) { FactoryGirl.create(:submission, user: bad_user, problem: problem, status: :wrong) }
      before do
        assign(:submission, wrong_submission)
        assign(:correction, Correction.new)
      end
      
      it "shows the submission" do
        render template: "problems/show"
        expect(response).to render_template(:partial => "submissions/_show")
      end
    end
  end
  
  context "if the user solved the problem" do
    before do
      assign(:signed_in, true)
      assign(:current_user, good_user)
    end
        
    it "renders the page correctly" do
      render template: "problems/show"
      expect(rendered).not_to have_text("Ce problème ne fait partie d'aucun test virtuel")
      expect(rendered).not_to have_selector("h3", text: "Prérequis")
      expect(rendered).to have_text(problem.statement)
      expect(rendered).to have_text(problem.origin)
      expect(rendered).not_to have_link("Modifier ce problème")
      expect(response).to render_template(:partial => "submissions/_index", :locals => {problem: problem})
      expect(rendered).not_to have_link("Nouvelle soumission")
      expect(rendered).not_to have_button("Éléments de solution")
    end
    
    context "and tries to write a new submission" do
      let!(:new_submission) { Submission.new }
      before { assign(:submission, new_submission) }
      
      it "does not render the form" do
        render template: "problems/show"
        expect(response).not_to render_template(:partial => "submissions/_new")
      end
    end
    
    context "and tries to see his own submission" do
      before do
        assign(:submission, user_submission)
        assign(:correction, Correction.new)
      end
      
      it "shows the submission" do
        render template: "problems/show"
        expect(response).to render_template(:partial => "submissions/_show")
      end
    end
    
    context "and tries to see a submission of someone else" do
      before { assign(:submission, corrector_submission) }
      
      it "shows the submission" do
        render template: "problems/show"
        expect(response).to render_template(:partial => "submissions/_show")
      end
    end
    
    context "and tries to see a wrong submission of someone else" do
      let!(:wrong_submission) { FactoryGirl.create(:submission, user: bad_user, problem: problem, status: :wrong) }
      before { assign(:submission, wrong_submission) }
      
      it "does not show the submission" do
        render template: "problems/show"
        expect(response).not_to render_template(:partial => "submissions/_show")
      end
    end
  end
  
  context "if the user is a corrector having solved the problem" do
    before do
      assign(:signed_in, true)
      assign(:current_user, good_corrector)
    end
     
    it "shows the explanation" do
      render template: "problems/show"
      expect(rendered).to have_button("Éléments de solution")
    end
    
    context "and tries to see a waiting submission" do
      let!(:waiting_submission) { FactoryGirl.create(:submission, user: bad_user, problem: problem, status: :waiting) }
      before do
        assign(:submission, waiting_submission)
        assign(:correction, Correction.new)
      end
      
      it "shows the submission" do
        render template: "problems/show"
        expect(response).to render_template(:partial => "submissions/_show")
      end
    end
  end
  
  context "if the user is a corrector not having solved the problem" do
    before do
      assign(:signed_in, true)
      assign(:current_user, bad_corrector)
    end
     
    it "does not show the explanation" do
      render template: "problems/show"
      expect(rendered).not_to have_button("Éléments de solution")
    end
    
    context "and tries to see a waiting submission" do
      let!(:waiting_submission) { FactoryGirl.create(:submission, user: bad_user, problem: problem, status: :waiting) }
      before { assign(:submission, waiting_submission) }
      
      it "does not show the submission" do
        render template: "problems/show"
        expect(response).not_to render_template(:partial => "submissions/_show")
      end
    end
  end
end
