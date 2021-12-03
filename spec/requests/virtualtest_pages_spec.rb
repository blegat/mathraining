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
  
  let(:attachments_folder) { "./spec/attachments/" }
  let(:image1) { "mathraining.png" } # default image used in factory
  let(:image2) { "Smiley1.gif" }
  let(:exe_attachment) { "hack.exe" }
  
  before do
    problem_with_prerequisite.chapters << chapter
  end
  
  describe "visitor" do
    describe "visits virtualtests page" do
      before { visit virtualtests_path }
      it do
        should have_selector("h1", text: "Tests virtuels")
        should have_selector("div", text: "Les tests virtuels ne sont accessibles qu'aux utilisateurs ayant un score d'au moins 200.")
      end
    end
    
    describe "tries visiting online virtualtest" do
      before { visit virtualtest_path(virtualtest) }
      it { should have_content(error_must_be_connected) }
    end
  end
  
  describe "user with rating 199" do
    before { sign_in user_with_rating_199 }

    describe "visits virtualtests page" do
      before { visit virtualtests_path }
      it do
        should have_selector("h1", text: "Tests virtuels")
        should have_selector("div", text: "Les tests virtuels ne sont accessibles qu'aux utilisateurs ayant un score d'au moins 200.")
      end
    end
    
    describe "tries visiting online virtualtest" do
      before { visit virtualtest_path(virtualtest) }
      it { should have_content(error_access_refused) }
    end
  end
  
  describe "user with rating 200" do
    before { sign_in user_with_rating_200 }

    describe "visits virtualtests page" do
      before { visit virtualtests_path }
      it do
        should have_selector("h1", text: "Tests virtuels")
        should have_no_selector("h3", text: "Test \##{virtualtest.number}")
      end
    end
    
    describe "tries visiting online virtualtest" do
      before { visit virtualtest_path(virtualtest) }
      it { should have_content(error_access_refused) }
    end
  end
  
  describe "user with rating 200 and completed chapter" do
    before do
      sign_in user_with_rating_200
      user_with_rating_200.chapters << chapter
    end

    describe "visits virtualtests page" do
      before { visit virtualtests_path }
      it do
        should have_selector("h1", text: "Tests virtuels")
        should have_selector("h3", text: "Test \##{virtualtest.number}")
        should have_content("2 problèmes")
        should have_no_content("Score moyen")
        should have_button("Commencer ce test")
      end
      
      describe "and starts the test" do
        before { click_button "Commencer ce test"  }
        it do
          should have_selector("h1", text: "Test \##{virtualtest.number}")
          should have_content("Temps restant")
          should have_link("Problème 1", href: virtualtest_path(virtualtest, :p => problem))
          should have_link("Problème 2", href: virtualtest_path(virtualtest, :p => problem_with_prerequisite))
        end
        
        describe "and visits the virtualtests" do
          before { visit virtualtests_path }
          it do
            should have_selector("h3", text: "Test \##{virtualtest.number}")
            should have_no_content("Score moyen")
            should have_no_button("Commencer ce test")
            should have_link("Problème 1", href: virtualtest_path(virtualtest, :p => problem))
            should have_content(problem.statement)
            should have_link("Problème 2", href: virtualtest_path(virtualtest, :p => problem_with_prerequisite))
            should have_content(problem_with_prerequisite.statement)
            should have_content("Temps restant")
          end
        end
        
        describe "and visits the problem in virtualtest" do
          before { visit virtualtest_path(virtualtest, :p => problem) }
          it do
            should have_selector("h3", text: "Énoncé")
            should have_content(problem.statement)
            should have_selector("h3", text: "Votre solution")
            should have_selector("span", text: "Vous n'avez pas encore envoyé de solution à ce problème.")
            should have_button("Écrire une solution")
            should have_button("Enregistrer cette solution") # NB: Users actually need to click on "Écrire une solution" to see the form
          end
          
          describe "and writes a solution" do
            before do
              fill_in "MathInput", with: newsolution
              click_button "Enregistrer cette solution"
            end
            specify do
              expect(problem.submissions.order(:id).last.content).to eq(newsolution)
              expect(page).to have_success_message("Votre solution a bien été enregistrée.")
              expect(page).to have_content(newsolution)
              expect(page).to have_link("Modifier la solution")
              expect(page).to have_link("Supprimer la solution")
              expect { click_link "Supprimer la solution" }.to change{problem.submissions.count}.by(-1)
            end
            
            describe "and modifies the solution" do
              before do
                fill_in "MathInput", with: newsolution2
                click_button "Enregistrer cette solution"
              end
              specify do
                expect(problem.submissions.order(:id).last.content).to eq(newsolution2)
                expect(page).to have_success_message("Votre solution a bien été modifiée.")
                expect(page).to have_content(newsolution2)
              end
            end
            
            describe "and the time stops" do
              let!(:takentest) { Takentest.where(:user => user_with_rating_200, :virtualtest => virtualtest).first }
              before do
                takentest.taken_time = DateTime.now - virtualtest.duration - 1
                takentest.save
                visit virtualtest_path(virtualtest, :p => problem) # Should redirect to virtualtests page
              end
              it do
                should have_selector("h1", text: "Tests virtuels")
                should have_link("Problème 1", href: problem_path(problem, :sub => problem.submissions.where(:user => user_with_rating_200).first))
                should have_link("Problème 2", href: problem_path(problem_with_prerequisite))
                should have_content("? / 7") # Problème 1
                should have_content("0 / 7") # Problème 2 (no submission)
                should have_no_content("Temps restant")
              end
            end
          end
          
          describe "and writes an empty solution" do
            before do
              fill_in "MathInput", with: ""
              click_button "Enregistrer cette solution"
            end
            it { should have_error_message("Soumission doit être rempli") }
          end
          
          describe "and writes a new solution after having written another one in another tab" do
            let!(:submission) { FactoryGirl.create(:submission, problem: problem, user: user_with_rating_200, status: 0, intest: true, visible: false, content: newsolution) }
            before do
              fill_in "MathInput", with: newsolution2
              click_button "Enregistrer cette solution"
              submission.reload
            end
            specify do
              expect(submission.content).to eq(newsolution2)
              expect(page).to have_content("Votre solution a bien été modifiée.")
            end
          end
        end
        
        describe "and tries to visit the problem section page" do
          before { visit pb_sections_path(section) }
          it { should have_no_link("Problème \##{problem.id}", href: problem_path(problem)) }
        end
        
        describe "and tries to visit the problem page" do
          before { visit problem_path(problem) }
          it { should have_content(error_access_refused) }
        end
      end
    end
    
    describe "tries visiting online virtualtest without starting it" do
      before { visit virtualtest_path(virtualtest) }
      it { should have_content(error_access_refused) }
    end
  end
  
  describe "admin" do
    before { sign_in admin }
    
    describe "visits virtualtests page" do
      before { visit virtualtests_path }
      it do
        should have_selector("h1", text: "Tests virtuels")
        should have_selector("h3", text: "Test \##{virtualtest.number}")
        should have_content("2 problèmes")
        should have_content(problem.statement)
        should have_content("Score moyen")
        should have_no_button("Commencer ce test")
        should have_no_link("Modifier ce test")
        should have_no_link("Supprimer ce test")
        should have_no_button("Mettre en ligne")
        should have_link("Ajouter un test virtuel")
      end
    end
    
    describe "visits creation page" do
      before { visit new_virtualtest_path }
      it { should have_selector("h1", text: "Créer un test virtuel") }
      
      describe "and creates a new test" do
        before do
          fill_in "virtualtest[duration]", with: duration
          click_button "Créer"
        end
        specify do
          expect(Virtualtest.order(:id).last.duration).to eq(duration)
          expect(page).to have_success_message("Test virtuel ajouté.")
          expect(page).to have_selector("h1", text: "Tests virtuels")
          expect(page).to have_content("(en construction)")
          expect(page).to have_link("Modifier ce test")
          expect(page).to have_link("Supprimer ce test")
          expect(page).to have_no_button("Mettre en ligne")
          expect(page).to have_content("(Au moins un problème nécessaire)")
          expect { click_link "Supprimer ce test" }.to change(Virtualtest, :count).by(-1)
        end
        
        describe "and visits modification page" do
          before { click_link "Modifier ce test" }
          it { should have_selector("h1", text: "Modifier un test virtuel") }
          
          describe "and modifies the test" do
            before do
              fill_in "virtualtest[duration]", with: duration2
              click_button "Modifier"
            end
            specify do
              expect(Virtualtest.order(:id).last.duration).to eq(duration2)
              expect(page).to have_success_message("Test virtuel modifié.")
            end
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
      specify do
        expect(page).to have_button("Mettre en ligne")
        expect(page).to have_link("Supprimer ce test")
        expect(page).to have_link("bas", href: problem_order_plus_path(problem))
        expect(page).to have_no_link("haut", href: problem_order_minus_path(problem))
        expect(page).to have_no_link("bas", href: problem_order_plus_path(problem_with_prerequisite))
        expect(page).to have_link("haut", href: problem_order_minus_path(problem_with_prerequisite))
        expect { click_link("bas", href: problem_order_plus_path(problem)) and problem.reload and problem_with_prerequisite.reload }.to change{problem.position}.from(1).to(2) .and change{problem_with_prerequisite.position}.from(2).to(1)
        expect { click_link("haut", href: problem_order_minus_path(problem)) and problem.reload and problem_with_prerequisite.reload }.to change{problem.position}.from(2).to(1) .and change{problem_with_prerequisite.position}.from(1).to(2)
        expect { click_link "Supprimer ce test" }.to change(Virtualtest, :count).by(-1)
      end
      
      describe "and puts it online" do
        before do
          click_button "Mettre en ligne"
          virtualtest.reload
        end
        specify do
          expect(page).to have_success_message("Test virtuel mis en ligne.")
          expect(virtualtest.online).to eq(true)
        end
      end
      
      describe "and puts it online while an offline problem was added" do
        before do
          offline_problem.virtualtest = virtualtest
          offline_problem.save
          click_button "Mettre en ligne"
          virtualtest.reload
        end
        specify do
          expect(page).to have_no_content("Test virtuel mis en ligne.")
          expect(virtualtest.online).to eq(false)
        end
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
      it do
        should have_no_button("Mettre en ligne")
        should have_content("(Problèmes doivent être en ligne)")
      end
    end
  end
  
  # -- TESTS THAT REQUIRE JAVASCRIPT --
  
  describe "user with rating 200 and completed chapter", :js => true do
    before do
      sign_in user_with_rating_200
      user_with_rating_200.chapters << chapter
    end
  
    describe "writes a solution with a file" do
      before do
        visit virtualtests_path
        click_button "Commencer ce test"
        # No dialog box to accept in test environment: it was deactivated because we had issues with testing
        visit virtualtest_path(virtualtest, :p => problem)
        click_button "Écrire une solution"
        wait_for_ajax
        fill_in "MathInput", with: newsolution
        click_button "Ajouter une pièce jointe"
        wait_for_ajax
        attach_file("file_1", File.absolute_path(attachments_folder + image1))
        click_button "Ajouter une pièce jointe" # We don't fill file2
        wait_for_ajax
        click_button "Enregistrer cette solution"
      end
      let(:newsub) { problem.submissions.order(:id).last }
      specify do
        expect(newsub.content).to eq(newsolution)
        expect(newsub.myfiles.count).to eq(1)
        expect(newsub.myfiles.first.file.filename.to_s).to eq(image1)
      end
      
      describe "and replace the file by another one" do
        before do
          click_link "Modifier la solution"
          wait_for_ajax
          fill_in "MathInput", with: newsolution2
          uncheck "prevFile_1"
          click_button "Ajouter une pièce jointe"
          wait_for_ajax
          attach_file("file_1", File.absolute_path(attachments_folder + image2))
          click_button "Enregistrer cette solution"
          newsub.reload
        end
        specify do
          expect(newsub.content).to eq(newsolution2)
          expect(newsub.myfiles.count).to eq(1)
          expect(newsub.myfiles.first.file.filename.to_s).to eq(image2)
        end
      end
    end
    
    describe "writes a solution with a wrong file" do
      before do
        visit virtualtests_path
        click_button "Commencer ce test"
        # No dialog box to accept in test environment: it was deactivated because we had issues with testing
        visit virtualtest_path(virtualtest, :p => problem)
        click_button "Écrire une solution"
        wait_for_ajax
        fill_in "MathInput", with: newsolution
        click_button "Ajouter une pièce jointe"
        wait_for_ajax
        attach_file("file_1", File.absolute_path(attachments_folder + exe_attachment))
        click_button "Enregistrer cette solution"
      end
      it do
        should have_error_message("Votre pièce jointe '#{exe_attachment}' ne respecte pas les conditions")
        should have_selector("textarea", text: newsolution)
      end
    end
  end
end
