# -*- coding: utf-8 -*-
require "spec_helper"

describe "Virtualtest pages" do

  subject { page }

  let(:admin) { FactoryGirl.create(:admin) }
  let(:user_with_rating_199) { FactoryGirl.create(:user, rating: 199) }
  let(:user_with_rating_200) { FactoryGirl.create(:user, rating: 200) }
  let!(:section) { FactoryGirl.create(:section) }
  let!(:chapter) { FactoryGirl.create(:chapter, online: true, name: "Mon chapitre prérequis") }
  let!(:virtualtest) { FactoryGirl.create(:virtualtest, online: true, number: 42) }
  let!(:problem) { FactoryGirl.create(:problem, section: section, online: true, level: 1, number: 1123, virtualtest: virtualtest, position: 1, statement: "Statement1") }
  let!(:problem_with_prerequisite) { FactoryGirl.create(:problem, section: section, online: true, level: 2, number: 1224, virtualtest: virtualtest, position: 2, statement: "Statement2") }
  let!(:offline_problem) { FactoryGirl.create(:problem, section: section, online: false, level: 3, number: 1345, position: 3, statement: "Statement3") }
  
  let!(:newsolution) { "Voici ma solution à votre problème" }
  let!(:newsolution2) { "Finalement voici une autre solution" }
  let!(:duration) { 60 }
  let!(:duration2) { 70 }
  
  before do
    problem_with_prerequisite.chapters << chapter
  end
  
  describe "visitor" do
    describe "visits virtualtests page" do
      before { visit virtualtests_path }
      it { should have_selector("h1", text: "Tests virtuels") }
      it { should have_selector("div", text: "Les tests virtuels ne sont accessibles qu'aux utilisateurs connectés ayant un score d'au moins 200.") }
    end
    
    describe "tries visiting online virtualtest" do
      before { visit virtualtest_path(virtualtest.id) }
      it { should have_selector("div", text: "Vous devez être connecté pour accéder à cette page.") }
    end
  end
  
  describe "user with rating 199" do
    before { sign_in user_with_rating_199 }

    describe "visits virtualtests page" do
      before { visit virtualtests_path }
      it { should have_selector("h1", text: "Tests virtuels") }
      it { should have_selector("div", text: "Les tests virtuels ne sont accessibles qu'aux utilisateurs ayant un score d'au moins 200.") }
    end
    
    describe "tries visiting online virtualtest" do
      before { visit virtualtest_path(virtualtest.id) }
      it { should have_selector("div", text: "Désolé... Cette page n'existe pas ou vous n'y avez pas accès.") }
    end
  end
  
  describe "user with rating 200" do
    before { sign_in user_with_rating_200 }

    describe "visits virtualtests page" do
      before { visit virtualtests_path }
      it { should have_selector("h1", text: "Tests virtuels") }
      it { should_not have_selector("h3", text: "Test \##{virtualtest.number}") }
    end
    
    describe "tries visiting online virtualtest" do
      before { visit virtualtest_path(virtualtest.id) }
      it { should have_selector("div", text: "Désolé... Cette page n'existe pas ou vous n'y avez pas accès.") }
    end
  end
  
  describe "user with rating 200 and completed chapter" do
    before do
      sign_in user_with_rating_200
      user_with_rating_200.chapters << chapter
    end

    describe "visits virtualtests page" do
      before { visit virtualtests_path }
      it { should have_selector("h1", text: "Tests virtuels") }
      it { should have_selector("h3", text: "Test \##{virtualtest.number}") }
      it { should have_content("2 problèmes") }
      it { should_not have_content("Score moyen") }
      it { should have_button("Commencer ce test") }
      
      describe "and starts the test" do
        before { click_button("Commencer ce test") }
        it { should have_selector("h1", text: "Test \##{virtualtest.number}") }
        it { should have_content("Temps restant") }
        it { should have_link("Problème 1", href: virtualtest_path(virtualtest.id, :p => problem.id)) }
        it { should have_link("Problème 2", href: virtualtest_path(virtualtest.id, :p => problem_with_prerequisite.id)) }
        
        describe "and visits the virtualtests" do
          before { visit virtualtests_path }
          it { should have_selector("h3", text: "Test \##{virtualtest.number}") }
          it { should_not have_content("Score moyen") }
          it { should_not have_button("Commencer ce test") }
          it { should have_link("Problème 1", href: virtualtest_path(virtualtest.id, :p => problem.id)) }
          it { should have_content(problem.statement) }
          it { should have_link("Problème 2", href: virtualtest_path(virtualtest.id, :p => problem_with_prerequisite.id)) }
          it { should have_content(problem_with_prerequisite.statement) }
          it { should have_content("Temps restant") }
        end
        
        describe "and visits the problem in virtualtest" do
          before { visit virtualtest_path(virtualtest.id, :p => problem.id) }
          it { should have_selector("h3", text: "Énoncé") }
          it { should have_content(problem.statement) }
          it { should have_selector("h3", text: "Votre solution") }
          it { should have_selector("span", text: "Vous n'avez pas encore envoyé de solution à ce problème.") }
          it { should have_button("Écrire une solution") }
          it { should have_button("Enregistrer cette solution") } # NB: Users actually need to click on "Écrire une solution" to see the form
          
          describe "and writes a solution" do
            before do
              fill_in "MathInput", with: newsolution
              click_button("Enregistrer cette solution")
            end
            it { should have_content("Votre solution a bien été enregistrée.") }
            specify { expect(problem.submissions.order(:id).last.content).to eq(newsolution) }
            it { should have_content(newsolution) }
            it { should have_link("Modifier la solution") }
            it { should have_link("Supprimer la solution") }
            specify { expect { click_link("Supprimer la solution") }.to change{problem.submissions.count}.by(-1) }
            
            describe "and modifies the solution" do
              before do
                fill_in "MathInput", with: newsolution2
                click_button("Enregistrer cette solution")
              end
              it { should have_content("Votre solution a bien été modifiée.") }
              specify { expect(problem.submissions.order(:id).last.content).to eq(newsolution2) }
              it { should have_content(newsolution2) }
            end
            
            describe "and the time stops" do
              let!(:takentest) { Takentest.where(:user => user_with_rating_200, :virtualtest => virtualtest).first }
              before do
                takentest.takentime = DateTime.now - virtualtest.duration - 1
                takentest.save
                visit virtualtest_path(virtualtest.id, :p => problem.id) # Should redirect to virtualtests page
              end
              it { should have_selector("h1", text: "Tests virtuels") }
              it { should have_link("Problème 1", href: problem_path(problem.id, :sub => problem.submissions.where(:user => user_with_rating_200).first.id)) }
              it { should have_link("Problème 2", href: problem_path(problem_with_prerequisite.id)) }
              it { should have_content("? / 7") } # Problème 1
              it { should have_content("0 / 7") } # Problème 2 (no submission)
              it { should_not have_content("Temps restant") }
            end
          end
        end
        
        describe "and tries to visit the problem section page" do
          before { visit pb_sections_path(section.id) }
          it { should_not have_link("Problème \##{problem.id}", href: problem_path(problem.id)) }
        end
        
        describe "and tries to visit the problem page" do
          before { visit problem_path(problem.id) }
          it { should_not have_selector("h1", text: "Problème \##{problem.id}") }
          it { should have_content("Désolé... Cette page n'existe pas ou vous n'y avez pas accès.") }
        end
      end
    end
    
    describe "tries visiting online virtualtest without starting it" do
      before { visit virtualtest_path(virtualtest.id) } # Should redirect to virtualtests_path
      it { should have_selector("h1", text: "Tests virtuels") }
    end
  end
  
  describe "admin" do
    before { sign_in admin }
    
    describe "visits virtualtests page" do
      before { visit virtualtests_path }
      it { should have_selector("h1", text: "Tests virtuels") }
      it { should have_selector("h3", text: "Test \##{virtualtest.number}") }
      it { should have_content("2 problèmes") }
      it { should have_content(problem.statement) }
      it { should have_content("Score moyen") }
      it { should_not have_button("Commencer ce test") }
      it { should_not have_link("Modifier ce test") }
      it { should_not have_link("Supprimer ce test") }
      it { should_not have_button("Mettre en ligne") }
      it { should have_link("Ajouter un test virtuel") }
    end
    
    describe "visits creation page" do
      before { visit new_virtualtest_path }
      it { should have_selector("h1", text: "Créer un test virtuel") }
      
      describe "and creates a new test" do
        before do
          fill_in "virtualtest[duration]", with: duration
          click_button("Créer")
        end
        specify { expect(Virtualtest.order(:id).last.duration).to eq(duration) }
        it { should have_content("Test virtuel ajouté.") }
        it { should have_selector("h1", text: "Tests virtuels") }
        it { should have_content("(en construction)") }
        it { should have_link("Modifier ce test") }
        it { should have_link("Supprimer ce test") }
        it { should_not have_button("Mettre en ligne") }
        it { should have_content("(Au moins un problème nécessaire)") }
        specify { expect { click_link("Supprimer ce test") }.to change(Virtualtest, :count).by(-1) }
        
        describe "and visits modification page" do
          before { click_link("Modifier ce test") }
          it { should have_selector("h1", text: "Modifier un test virtuel") }
          
          describe "and modifies the test" do
            before do
              fill_in "virtualtest[duration]", with: duration2
              click_button("Modifier")
            end
            specify { expect(Virtualtest.order(:id).last.duration).to eq(duration2) }
            it { should have_content("Test virtuel modifié.") }
          end
        end
      end
    end
    
    describe "visits an offline test with online problems" do
      before do
        virtualtest.online = false
        virtualtest.save
        visit virtualtests_path
      end
      it { should have_button("Mettre en ligne") }
      it { should have_link("Supprimer ce test") }
      specify { expect { click_link("Supprimer ce test") }.to change(Virtualtest, :count).by(-1) }
      
      describe "and puts it online" do
        before do
          click_button("Mettre en ligne")
          virtualtest.reload
        end
        it { should have_content("Test virtuel mis en ligne.") }
        specify { expect(virtualtest.online).to eq(true) }
      end
      
      describe "and puts it online while an offline problem was added" do
        before do
          offline_problem.virtualtest = virtualtest
          offline_problem.save
          click_button("Mettre en ligne")
          virtualtest.reload
        end
        it { should_not have_content("Test virtuel mis en ligne.") }
        specify { expect(virtualtest.online).to eq(false) }
      end
    end
    
    describe "visits an offline test with an offline problem" do
      before do
        virtualtest.online = false
        virtualtest.save
        problem.online = false
        problem.save
        visit virtualtests_path
      end
      it { should_not have_button("Mettre en ligne") }
      it { should have_content("(Problèmes doivent être en ligne)") }
    end
  end
end
