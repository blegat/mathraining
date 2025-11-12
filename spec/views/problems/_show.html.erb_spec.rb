# -*- coding: utf-8 -*-
require "spec_helper"

describe "problems/_show.html.erb", type: :view, problem: true do

  subject { rendered }

  let(:admin) { FactoryBot.create(:admin) }
  let(:bad_user) { FactoryBot.create(:advanced_user) }
  let(:good_user) { FactoryBot.create(:advanced_user) }
  let(:bad_corrector) { FactoryBot.create(:corrector) }
  let(:good_corrector) { FactoryBot.create(:corrector) }
  let(:chapter) { FactoryBot.create(:chapter, online: true) }
  let!(:problem) { FactoryBot.create(:problem, online: true, explanation: "Voici la solution") }
  let!(:offline_virtualtest) { FactoryBot.create(:virtualtest, online: false) }
  let!(:user_submission) { FactoryBot.create(:submission, user: good_user, problem: problem, status: :correct) }
  let!(:user_sp) { FactoryBot.create(:solvedproblem, user: good_user, problem: problem, submission: user_submission) }
  let!(:corrector_submission) { FactoryBot.create(:submission, user: good_corrector, problem: problem, status: :correct) }
  let!(:corrector_sp) { FactoryBot.create(:solvedproblem, user: good_corrector, problem: problem, submission: corrector_submission) }
  
  before do
    assign(:problem, problem)
    problem.chapters << chapter
    bad_user.chapters << chapter
    good_user.chapters << chapter
    bad_corrector.chapters << chapter
    good_corrector.chapters << chapter
  end
  
  context "if the user is an admin" do
    before { sign_in_view(admin) }
    
    context "if the problem is offline" do
      before { problem.update_attribute(:online, false) }
      
      it "renders the page correctly" do
        render partial: "problems/show"
        should have_content("Ce problème ne fait partie d'aucun test virtuel")
        should have_content("Faire appartenir ce problème à")
        should have_selector("h3", text: "Prérequis")
        should have_link(chapter.name, href: chapter_path(chapter))
        should have_link("Supprimer ce prérequis", href: delete_prerequisite_problem_path(problem, :chapter_id => chapter.id))
        should have_content("Ajouter le prérequis :")
        should have_content(problem.statement)
        should have_content(problem.origin)
        should have_link("Modifier ce problème")
        should have_link("Modifier la solution")
        should have_link("Modifier les solutions externes")
        should have_link("Supprimer ce problème")
        should have_link("Mettre en ligne")
        expect(response).not_to render_template(:partial => "submissions/_index", :locals => {problem: problem})
        should have_no_link("Nouvelle soumission")
        should have_button("Éléments de solution")
      end
      
      context "but its prerequisite is offline" do
        before { chapter.update_attribute(:online, false) }
        
        it "does not render the put online button" do
          render partial: "problems/show"
          should have_link("Mettre en ligne", class: "btn btn-danger disabled")
          should have_content("(Chapitres prérequis doivent être en ligne)")
        end
      end
      
       context "but it has no prerequisite" do
        before { problem.chapters.delete(chapter) }
        
        it "does not render the put online button" do
          render partial: "problems/show"
          should have_link("Mettre en ligne", class: "btn btn-danger disabled")
          should have_content("(Au moins un chapitre prérequis nécessaire)")
        end
      end
    end
    
    context "if the problem is online" do      
      it "renders the page correctly" do
        render partial: "problems/show"
        should have_no_content("Ce problème ne fait partie d'aucun test virtuel")
        should have_no_content("Faire appartenir ce problème à")
        should have_selector("h3", text: "Prérequis")
        should have_link(chapter.name, href: chapter_path(chapter))
        should have_no_link("Supprimer ce prérequis", href: delete_prerequisite_problem_path(problem, :chapter_id => chapter.id))
        should have_no_content("Ajouter le prérequis :")
        should have_content(problem.statement)
        should have_content(problem.origin)
        should have_link("Modifier ce problème")
        should have_link("Modifier la solution")
        should have_link("Modifier les solutions externes")
        should have_no_link("Supprimer ce problème")
        should have_no_link("Mettre en ligne")
        expect(response).to render_template(:partial => "submissions/_index", :locals => {problem: problem})
        should have_no_link("Nouvelle soumission")
        should have_button("Éléments de solution")
      end
    end
  end
  
  context "if the user didn't solve the problem" do
    before { sign_in_view(bad_user) }
        
    it "renders the page correctly" do
      render partial: "problems/show"
      should have_no_content("Ce problème ne fait partie d'aucun test virtuel")
      should have_no_selector("h3", text: "Prérequis")
      should have_content(problem.statement)
      should have_no_content(problem.origin)
      should have_no_link("Modifier ce problème")
      expect(response).to render_template(:partial => "submissions/_index", :locals => {problem: problem})
      should have_link("Nouvelle soumission")
      should have_no_button("Éléments de solution")
    end
    
    context "but has a draft" do
      let!(:draft) { FactoryBot.create(:submission, problem: problem, user: bad_user, :status => :draft) }
      it "does not show the new submission button" do
        render partial: "problems/show"
        should have_no_link("Nouvelle soumission")
        should have_link("Reprendre le brouillon")
      end
    end
    
    context "but we should not show the new submission button" do
      it "does not show the new submission button" do
        render partial: "problems/show", locals: {show_new_button: false}
        should have_no_link("Nouvelle soumission")
        should have_no_link("Reprendre le brouillon")
      end
    end
  end
  
  context "if the user solved the problem" do
    before { sign_in_view(good_user) }
        
    it "renders the page correctly" do
      render partial: "problems/show"
      should have_no_content("Ce problème ne fait partie d'aucun test virtuel")
      should have_no_selector("h3", text: "Prérequis")
      should have_content(problem.statement)
      should have_content(problem.origin)
      should have_no_link("Modifier ce problème")
      expect(response).to render_template(:partial => "submissions/_index", :locals => {problem: problem})
      should have_no_link("Nouvelle soumission")
      should have_no_button("Éléments de solution")
    end
  end
  
  context "if the user is a corrector having solved the problem" do
    before { sign_in_view(good_corrector) }
     
    it "shows the explanation" do
      render partial: "problems/show"
      should have_button("Éléments de solution")
    end
  end
  
  context "if the user is a corrector not having solved the problem" do
    before { sign_in_view(bad_corrector) }
     
    it "does not show the explanation" do
      render partial: "problems/show"
      should have_no_button("Éléments de solution")
    end
  end
end
