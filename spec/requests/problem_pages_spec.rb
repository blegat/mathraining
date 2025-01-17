# -*- coding: utf-8 -*-
require "spec_helper"

describe "Problem pages", problem: true do

  subject { page }

  let(:admin) { FactoryGirl.create(:admin) }
  let(:user_with_rating_199) { FactoryGirl.create(:user, rating: 199) }
  let(:user_with_rating_200) { FactoryGirl.create(:user, rating: 200) }
  let!(:section) { FactoryGirl.create(:section) }
  let!(:chapter) { FactoryGirl.create(:chapter, online: true, name: "Mon chapitre prérequis") }
  let!(:online_problem) { FactoryGirl.create(:problem, section: section, online: true, level: 1, number: 1123, statement: "Statement1") }
  let!(:online_problem_with_prerequisite) { FactoryGirl.create(:problem, section: section, online: true, level: 1, number: 1124, statement: "Statement2") }
  let!(:offline_problem) { FactoryGirl.create(:problem, section: section, online: false, level: 1, number: 1134, statement: "Statement3") }
  let!(:online_virtualtest) { FactoryGirl.create(:virtualtest, online: true, number: 42, duration: 10) }
  let!(:problem_in_virtualtest) { FactoryGirl.create(:problem, section: section, online: true, level: 2, number: 1256, statement: "Statement4", position: 1, virtualtest: online_virtualtest) }
  let!(:offline_virtualtest) { FactoryGirl.create(:virtualtest, online: false, number: 23, duration: 15) }
  
  let(:newstatement) { "Prière de résoudre ce problème de combinatoire." }
  let(:neworigin) { "Origine du problème" }
  let(:newlevel) { 5 }
  let(:newexplanation) { "Explication du problème pour les correcteurs." }
  let(:newmarkscheme) { "Marking scheme pour un problème de test virtuel." }
  let(:no_new_sub_message) {"On ne soumet plus pour l'instant !" }
  
  before do
    online_problem_with_prerequisite.chapters << chapter
  end
  
  describe "visitor" do
    describe "visits problems of a section" do
      before { visit section_problems_path(section) }
      it do
        should have_selector("h1", text: section.name)
        should have_selector("div", text: "Les problèmes ne sont accessibles qu'aux utilisateurs ayant un score d'au moins 200.")
      end
    end
  end
  
  describe "user with rating 199" do
    before { sign_in user_with_rating_199 }

    describe "visits problems of a section" do
      before { visit section_problems_path(section) }
      it do
        should have_selector("h1", text: section.name)
        should have_selector("div", text: "Les problèmes ne sont accessibles qu'aux utilisateurs ayant un score d'au moins 200.")
      end
    end
  end
  
  describe "user with rating 200" do
    before { sign_in user_with_rating_200 }

    describe "visits problems of a section" do
      before { visit section_problems_path(section) }
      it do
        should have_selector("h1", text: section.name)
        should have_no_selector("div", text: "Les problèmes ne sont accessibles qu'aux utilisateurs ayant un score d'au moins 200.")
        should have_selector("h3", text: "Niveau 1")
        should have_link("Problème ##{online_problem.number}", href: problem_path(online_problem, :auto => 1))
        should have_selector("div", text: online_problem.statement)
        should have_no_link("Problème ##{offline_problem.number}", href: problem_path(offline_problem, :auto => 1))
        should have_no_selector("div", text: offline_problem.statement) 
        should have_no_link("Problème ##{problem_in_virtualtest.number}", href: problem_path(problem_in_virtualtest, :auto => 1)) 
        should have_no_selector("div", text: problem_in_virtualtest.statement) 
        should have_no_link("Problème ##{online_problem_with_prerequisite.number}", href: problem_path(online_problem_with_prerequisite, :auto => 1)) 
        should have_no_selector("div", text: online_problem_with_prerequisite.statement)
      end
    end
    
    describe "visits online problem" do
      before { visit problem_path(online_problem) }
      it do
        should have_selector("h1", text: "Problème ##{online_problem.number}")
        should have_selector("div", text: online_problem.statement)
      end
    end
    
    describe "visits online problem with auto param" do
      let!(:correct_submission) { FactoryGirl.create(:submission, :user => user_with_rating_200, :problem => online_problem, :status => :correct) }
      let!(:solvedproblem) { FactoryGirl.create(:solvedproblem, :user => user_with_rating_200, :problem => online_problem, :submission => correct_submission) }
      before { visit problem_path(online_problem, :auto => 1) }
      it do
        should have_current_path(problem_path(online_problem, :sub => correct_submission))
        should have_content(correct_submission.content)
      end
    end
    
    describe "visits online problem with auto param when not solved" do
      let!(:incorrect_submission) { FactoryGirl.create(:submission, :user => user_with_rating_200, :problem => online_problem, :status => :wrong) }
      before { visit problem_path(online_problem, :auto => 1) }
      it do
        should have_current_path(problem_path(online_problem))
        should have_no_content(incorrect_submission.content)
      end
    end
  end
  
  describe "user with rating 200 and completed chapter" do
    before do
      sign_in user_with_rating_200
      user_with_rating_200.chapters << chapter
    end

    describe "visits problems of a section" do
      before { visit section_problems_path(section) }
      it do
        should have_link("Problème ##{online_problem_with_prerequisite.number}", href: problem_path(online_problem_with_prerequisite, :auto => 1))
        should have_selector("div", text: online_problem_with_prerequisite.statement)
        should have_no_button("Ajouter un problème")
      end
    end
    
    describe "visits problems of a section while no new submissions are allowed" do
      before do
        Globalvariable.create(:key => "no_new_submission", :value => 1, :message => no_new_sub_message)
        visit section_problems_path(section)
      end
      it do
        should have_info_message(no_new_sub_message)
        should have_no_link("Problème ##{online_problem_with_prerequisite.number}", href: problem_path(online_problem_with_prerequisite, :auto => 1))
      end
    end
    
    describe "visits online problem with prerequisite" do
      before { visit problem_path(online_problem_with_prerequisite) }
      it do
        should have_selector("h1", text: "Problème ##{online_problem_with_prerequisite.number}")
        should have_selector("div", text: online_problem_with_prerequisite.statement)
        should have_no_link("Modifier ce problème")
        should have_no_link("Modifier la solution")
      end
    end

  end
  
  describe "admin" do
    before { sign_in admin }
    
    describe "visits problems of a section" do
      before { visit section_problems_path(section) }
      it do
        should have_selector("h1", text: section.name)
        should have_no_selector("div", text: "Les problèmes ne sont accessibles qu'aux utilisateurs ayant un score d'au moins 200.")
        should have_selector("h3", text: "Niveau 1")
        should have_link("Problème ##{online_problem.number}", href: problem_path(online_problem, :auto => 1))
        should have_selector("div", text: online_problem.statement)
        should have_link("Problème ##{offline_problem.number}", href: problem_path(offline_problem, :auto => 1))
        should have_selector("div", text: offline_problem.statement)
        should have_link("Problème ##{problem_in_virtualtest.number}", href: problem_path(problem_in_virtualtest, :auto => 1))
        should have_selector("div", text: problem_in_virtualtest.statement)
        should have_link("Problème ##{online_problem_with_prerequisite.number}", href: problem_path(online_problem_with_prerequisite, :auto => 1))
        should have_selector("div", text: online_problem_with_prerequisite.statement)
      end
    end
    
    describe "visits online problem" do
      before { visit problem_path(online_problem) }
      it do
        should have_selector("h1", text: "Problème ##{online_problem.number}")
        should have_selector("div", text: online_problem.statement)
        should have_link("Modifier ce problème", href: edit_problem_path(online_problem))
        should have_link("Modifier la solution", href: edit_explanation_problem_path(online_problem))
        should have_no_link("Supprimer ce problème")
      end
    end
    
    describe "visits virtualtest problem" do
      before { visit problem_path(problem_in_virtualtest) }
      it do
        should have_selector("h1", text: "Problème ##{problem_in_virtualtest.number} - Test ##{online_virtualtest.number}")
        should have_link("Modifier le marking scheme", href: edit_markscheme_problem_path(problem_in_virtualtest))
      end
    end
    
    describe "visits offline problem" do
      before { visit problem_path(offline_problem) }
      it do
        should have_selector("h1", text: "Problème ##{offline_problem.number}")
        should have_selector("div", text: offline_problem.statement)
        should have_link("Supprimer ce problème")
        should have_no_button("Mettre en ligne") # Because no prerequisite
      end
      
      specify { expect { click_link "Supprimer ce problème" }.to change(Problem, :count).by(-1) }
      
      describe "and adds a prerequisite" do
        before do
          select chapter.name, :from => "chapter_problem_chapter_id"
          click_button "new_prerequisite_button"
        end
        it do
          should have_selector("h1", text: "Problème ##{offline_problem.number}")
          should have_link(chapter.name, href: chapter_path(chapter))
          should have_link("Supprimer ce prérequis", href: delete_prerequisite_problem_path(offline_problem, :chapter_id => chapter))
          should have_button("Mettre en ligne")
        end
        
        describe "and deletes a prerequisite" do
          before { click_link("Supprimer ce prérequis") }
          it do
            should have_selector("h1", text: "Problème ##{offline_problem.number}")
            should have_no_link(chapter.name, href: chapter_path(chapter))
          end
        end
        
        describe "and adds to a virtualtest" do
          before do
            select "Test virtuel ##{offline_virtualtest.number}", :from => "problem_virtualtest_id"
            click_button "add_to_virtualtest_button"
          end
          it { should have_selector("h1", text: "Problème ##{offline_problem.number} - Test ##{offline_virtualtest.number}") }
          
          describe "and removes from virtualtest" do
            before do
              select "Aucun test virtuel", :from => "problem_virtualtest_id"
              click_button "add_to_virtualtest_button"
            end
            it do
              should have_selector("h1", text: "Problème ##{offline_problem.number}")
              should have_no_selector("h1", text: "Problème ##{offline_problem.number} - Test virtuel ##{offline_virtualtest.number}")
            end
          end
        end
        
        describe "and puts online" do
          before do
            click_button "Mettre en ligne"
            offline_problem.reload
          end
          specify { expect(offline_problem.online).to eq(true) }
        end
      end
    end
    
    describe "visits edit explanation page" do
      before { visit edit_explanation_problem_path(online_problem) }
      it { should have_selector("h1", text: "Modifier la solution") }
      
      describe "and modifies it" do
        before do
          fill_in "MathInput", with: newexplanation
          click_button "Modifier"
          online_problem.reload
        end
        specify { expect(online_problem.explanation).to eq(newexplanation) }
      end
      
      describe "and modifies it with empty string" do
        before do
          fill_in "MathInput", with: ""
          click_button "Modifier"
          online_problem.reload
        end
        specify do
          expect(online_problem.explanation).not_to eq("")
          expect(page).to have_error_message("Éléments de solution doit être rempli")
        end
      end
    end
    
    describe "visits edit markscheme page" do
      before { visit edit_markscheme_problem_path(problem_in_virtualtest) }
      it { should have_selector("h1", text: "Modifier le marking scheme") }
      
      describe "and modifies it" do
        before do
          fill_in "MathInput", with: newmarkscheme
          click_button "Modifier"
          problem_in_virtualtest.reload
        end
        specify { expect(problem_in_virtualtest.markscheme).to eq(newmarkscheme) }
      end
      
      describe "and modifies it with empty string" do
        before do
          fill_in "MathInput", with: ""
          click_button "Modifier"
          problem_in_virtualtest.reload
        end
        specify do
          expect(problem_in_virtualtest.markscheme).not_to eq("")
          expect(page).to have_error_message("Marking scheme doit être rempli")
        end
      end
    end
    
    describe "visits problem creation page" do
      before { visit new_section_problem_path(section) }
      it { should have_selector("h1", text: "Créer un problème") }
      
      describe "and sends with good information" do
        before do
          fill_in "MathInput", with: newstatement
          fill_in "Origine", with: neworigin
          fill_in "Niveau", with: newlevel
          click_button "Créer"
        end
        specify do
          expect(Problem.order(:id).last.statement).to eq(newstatement)
          expect(Problem.order(:id).last.origin).to eq(neworigin)
          expect(Problem.order(:id).last.level).to eq(newlevel)
          expect(Problem.order(:id).last.number).to be >= 1000*section.id + 100*newlevel
          expect(Problem.order(:id).last.number).to be < 1000*section.id + 100*(newlevel+1)
          expect(Problem.order(:id).last.online).to eq(false)
          expect(page).to have_selector("div", text: newstatement)
          expect(page).to have_no_button("Mettre en ligne") # Because no prerequisite
        end
      end
      
      describe "and sends with wrong information" do
        before do
          fill_in "MathInput", with: ""
          fill_in "Origine", with: neworigin
          fill_in "Niveau", with: newlevel
          click_button "Créer"
        end
        specify do
          expect(page).to have_error_message("erreur")
          expect(page).to have_selector("h1", text: "Créer un problème")
          expect(Problem.order(:id).last.origin).to_not eq(neworigin)
        end
      end
    end
    
    describe "visits problem modification page" do
      before { visit edit_problem_path(offline_problem) }
      it { should have_selector("h1", text: "Modifier") }
      
      describe "and sends with good information" do
        before do
          fill_in "MathInput", with: newstatement
          fill_in "Origine", with: neworigin
          fill_in "Niveau", with: newlevel
          click_button "Modifier"
          offline_problem.reload
        end
        specify do
          expect(offline_problem.statement).to eq(newstatement)
          expect(offline_problem.origin).to eq(neworigin)
          expect(offline_problem.level).to eq(newlevel)
          expect(offline_problem.number).to be >= 1000*section.id + 100*newlevel
          expect(offline_problem.number).to be < 1000*section.id + 100*(newlevel+1)
          expect(page).to have_selector("div", text: newstatement)
        end
      end
      
      describe "and sends with wrong information" do
        before do
          fill_in "MathInput", with: ""
          fill_in "Origine", with: neworigin
          fill_in "Niveau", with: newlevel
          click_button "Modifier"
          offline_problem.reload
        end
        specify do
          expect(page).to have_error_message("erreur")
          expect(page).to have_selector("h1", text: "Modifier")
          expect(offline_problem.origin).to_not eq(neworigin)
        end
      end
    end
  end
end
