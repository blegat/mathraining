# -*- coding: utf-8 -*-
require "spec_helper"

describe "Contestsolution pages" do

  subject { page }
  
  let(:datetime_before) { DateTime.now - 2.hours }
  let(:datetime_before2) { DateTime.now - 1.hour }
  let(:datetime_after) { DateTime.now + 1.hour }
  let(:datetime_after2) { DateTime.now + 2.hours }

  let(:root) { FactoryGirl.create(:root) }
  let(:user_with_rating_199) { FactoryGirl.create(:user, rating: 199) }
  let(:user_with_rating_200) { FactoryGirl.create(:user, rating: 200) }
  let!(:user_organizer) { FactoryGirl.create(:user, rating: 300) }
  
  let!(:contest) { FactoryGirl.create(:contest, status: 1) }
  let!(:contestproblem_finished) { FactoryGirl.create(:contestproblem, contest: contest, number: 1, start_time: datetime_before, end_time: datetime_before2, status: 3) }
  let!(:contestproblem_running) { FactoryGirl.create(:contestproblem, contest: contest, number: 2, start_time: datetime_before2, end_time: datetime_after, status: 2) }
  let!(:contestproblem_not_started) { FactoryGirl.create(:contestproblem, contest: contest, number: 3, start_time: datetime_after, end_time: datetime_after2, status: 1) }
  
  let(:officialsol_finished) { contestproblem_finished.contestsolutions.where(:official => true).first }
  let(:officialsol_running) { contestproblem_running.contestsolutions.where(:official => true).first }
  let(:officialsol_not_started) { contestproblem_not_started.contestsolutions.where(:official => true).first }
  
  let(:newsolution) { "Voici ma solution à ce beau problème" }
  let(:newsolution2) { "Voici ma nouvelle solution à ce beau problème" }
  
  let(:attachments_folder) { "./spec/attachments/" }
  let(:image1) { "mathraining.png" } # default image used in factory
  let(:image2) { "Smiley1.gif" }
  let(:exe_attachment) { "hack.exe" }
  
  before do
    Contestorganization.create(:contest => contest, :user => user_organizer)
  end
  
  describe "user with rating 199" do
    before { sign_in user_with_rating_199 }
    
    describe "visits one contest page" do
      before { visit contest_path(contest) }
      it do
        should have_link("Problème ##{contestproblem_finished.number}")
        should have_link("Problème ##{contestproblem_running.number}")
        should have_no_link("Problème ##{contestproblem_not_started.number}")
      end
    end

    describe "visits a running contestproblem page" do
      before { visit contestproblem_path(contestproblem_running) }
      it do
        should have_selector("h1", text: "Problème ##{contestproblem_running.number}")
        should have_content("Pour pouvoir participer aux concours, il faut avoir au moins 200 points.")
      end
    end
  end
  
  describe "user with rating 200" do
    before { sign_in user_with_rating_200 }
    
    describe "visits a finished contestproblem page" do
      before { visit contestproblem_path(contestproblem_finished) }
      it do
        should have_selector("h1", text: "Problème ##{contestproblem_finished.number}")
        should have_no_button("Enregistrer")
      end
    end
    
    describe "tries to visit a non-started contestproblem page" do
      before { visit contestproblem_path(contestproblem_not_started) }
      it { should have_content(error_access_refused) }
    end

    describe "visits a running contestproblem page" do
      before { visit contestproblem_path(contestproblem_running) }
      it do
        should have_selector("h1", text: "Problème ##{contestproblem_running.number}")
        should have_button("Enregistrer")
      end
      
      describe "and writes an empty solution" do
        before do
          fill_in "MathInput", with: ""
          click_button "Enregistrer"
        end
        specify do
          expect(page).to have_error_message("Solution doit être rempli")
          expect(contestproblem_running.contestsolutions.where(:user => user_with_rating_200).count).to eq(0)
        end
      end
      
      describe "and writes a solution too late" do
        before do
          contestproblem_running.status = 3
          contestproblem_running.save
          fill_in "MathInput", with: newsolution
          click_button "Enregistrer"
        end
        specify do
          expect(page).to have_error_message("Vous ne pouvez pas enregistrer cette solution.")
          expect(contestproblem_running.contestsolutions.where(:user => user_with_rating_200).count).to eq(0)
        end
      end
      
      describe "and writes two solutions at the same time" do # Can happen when someone has opened the problem in two windows
        before do
          Contestsolution.create(:user => user_with_rating_200, :contestproblem => contestproblem_running, :content => newsolution2)
          fill_in "MathInput", with: newsolution
          click_button "Enregistrer"
        end
        specify do
          expect(page).to have_content("Solution enregistrée.")
          expect(contestproblem_running.contestsolutions.where(:user => user_with_rating_200).count).to eq(1)
          expect(contestproblem_running.contestsolutions.where(:user => user_with_rating_200).first.content).to eq(newsolution)
        end
      end
      
      describe "and writes a solution" do
        before do
          fill_in "MathInput", with: newsolution
          click_button "Enregistrer"
        end
        let(:newcontestsolution) { contestproblem_running.contestsolutions.where(:user => user_with_rating_200).first }
        specify do
          expect(newcontestsolution).not_to eq(nil)
          expect(newcontestsolution.content).to eq(newsolution)
          expect(page).to have_success_message("Solution enregistrée.")
          expect(page).to have_link("Supprimer la solution")
          expect(page).to have_button("Enregistrer") # There is a form to edit the solution
        end
        
        specify { expect { click_link "Supprimer la solution" }.to change{contestproblem_running.contestsolutions.count}.by(-1) }
        
        describe "and edits the solution" do
          before do
            fill_in "MathInput", with: newsolution2
            click_button "Enregistrer"
            newcontestsolution.reload
          end
          specify do
            expect(page).to have_success_message("Solution enregistrée.")
            expect(newcontestsolution.content).to eq(newsolution2)
          end
        end
        
        describe "and edits with an empty solution" do
          before do
            fill_in "MathInput", with: ""
            click_button "Enregistrer"
            newcontestsolution.reload
          end
          specify do
            expect(page).to have_error_message("Solution doit être rempli")
            expect(newcontestsolution.content).to eq(newsolution)
          end
        end
        
        describe "and edits the solution too late" do
          before do
            contestproblem_running.status = 3
            contestproblem_running.save
            fill_in "MathInput", with: newsolution2
            click_button "Enregistrer"
          end
          specify do
            expect(page).to have_error_message("Vous ne pouvez pas enregistrer cette solution.")
            expect(newcontestsolution.content).to eq(newsolution)
          end
        end
        
        describe "and deletes the solution too late" do
          before do
            contestproblem_running.status = 3
            contestproblem_running.save
            click_link("Supprimer la solution")
          end
          specify do
            expect(page).to have_error_message("Vous ne pouvez pas supprimer cette solution.")
            expect(contestproblem_running.contestsolutions.where(:user => user_with_rating_200).count).to eq(1)
          end
        end
      end
    end
  end
  
  describe "organizer" do
    before { sign_in user_organizer }
    
    describe "tries to visit a non-started contestproblem page" do
      before { visit contestproblem_path(contestproblem_not_started) }
      it do
        should have_content("Ce problème n'est pas encore en ligne.")
        should have_link("cliquer ici", :href => contestproblem_path(contestproblem_not_started, :sol => officialsol_not_started))
        should have_no_button("Enregistrer")
      end
    end

    describe "visits a running contestproblem page" do
      before { visit contestproblem_path(contestproblem_running) }
      it do
        should have_selector("h1", text: "Problème ##{contestproblem_running.number}")
        should have_content("Ce problème est en train d'être résolu par les participants.")
        should have_link("cliquer ici", :href => contestproblem_path(contestproblem_running, :sol => officialsol_running))
        should have_no_button("Enregistrer")
      end
    end

    describe "visits a finished contestproblem page" do
      before do
        # Make sure that the official solution is starred so we can see it without javascript
        officialsol_finished.score = 7
        officialsol_finished.corrected = true
        officialsol_finished.star = true
        officialsol_finished.save
        visit contestproblem_path(contestproblem_finished)
      end
      it do
        should have_selector("h1", text: "Problème ##{contestproblem_finished.number}")
        should have_selector("h3", text: "Solutions étoilées")
        should have_link("Voir", :href => contestproblem_path(contestproblem_finished, :sol => officialsol_finished))
      end
    end
  end
  
  # -- TESTS THAT REQUIRE JAVASCRIPT --
  
  describe "user with rating 200", :js => true do
    before { sign_in user_with_rating_200 }
  
    describe "creates a solution with a file" do
      before do
        visit contestproblem_path(contestproblem_running)
        fill_in "MathInput", with: newsolution
        click_button "Ajouter une pièce jointe" # We don't fill file1
        wait_for_ajax
        click_button "Ajouter une pièce jointe"
        wait_for_ajax
        attach_file("file_2", File.absolute_path(attachments_folder + image2))
        click_button "Ajouter une pièce jointe" # We don't fill file3
        wait_for_ajax
        click_button "Enregistrer"
      end
      let(:newsol) { contestproblem_running.contestsolutions.order(:id).last }
      specify do
        expect(newsol.content).to eq(newsolution)
        expect(newsol.myfiles.count).to eq(1)
        expect(newsol.myfiles.first.file.filename.to_s).to eq(image2)
      end
    end
    
    describe "creates a solution with a exe file" do
      before do
        visit contestproblem_path(contestproblem_running)
        fill_in "MathInput", with: newsolution
        click_button "Ajouter une pièce jointe"
        wait_for_ajax
        attach_file("file_1", File.absolute_path(attachments_folder + exe_attachment))
        click_button "Enregistrer"
      end
      it do
        should have_error_message("Votre pièce jointe '#{exe_attachment}' ne respecte pas les conditions")
      end
    end
    
    describe "edits a solution with a file" do
      let!(:usercontestsolution) { FactoryGirl.create(:contestsolution, contestproblem: contestproblem_running, user: user_with_rating_200) }
      let!(:contestsolutionmyfile) { FactoryGirl.create(:contestsolutionmyfile, myfiletable: usercontestsolution) }
      before do
        visit contestproblem_path(contestproblem_running, :sol => usercontestsolution)
        click_link("Modifier la solution")
        wait_for_ajax
        uncheck "prevFile_1"
        fill_in "MathInput", with: newsolution2
        click_button "Ajouter une pièce jointe"
        wait_for_ajax
        attach_file("file_1", File.absolute_path(attachments_folder + image2))
        click_button "Enregistrer"
        usercontestsolution.reload
      end
      specify do
        expect(usercontestsolution.content).to eq(newsolution2)
        expect(usercontestsolution.myfiles.count).to eq(1)
        expect(usercontestsolution.myfiles.first.file.filename.to_s).to eq(image2)
      end
    end
    
    describe "edits a solution with too many files" do # 3 x image1 should do > 15 ko, which is the limit in test mode
      let!(:usercontestsolution) { FactoryGirl.create(:contestsolution, contestproblem: contestproblem_running, user: user_with_rating_200) }
      let!(:contestsolutionmyfile) { FactoryGirl.create(:contestsolutionmyfile, myfiletable: usercontestsolution) }
      before do
        visit contestproblem_path(contestproblem_running, :sol => usercontestsolution)
        click_link("Modifier la solution")
        wait_for_ajax
        fill_in "MathInput", with: newsolution2
        click_button "Ajouter une pièce jointe"
        wait_for_ajax
        attach_file("file_1", File.absolute_path(attachments_folder + image1))
        click_button "Ajouter une pièce jointe"
        wait_for_ajax
        attach_file("file_2", File.absolute_path(attachments_folder + image1))
        click_button "Enregistrer"
        usercontestsolution.reload
      end
      specify do
        expect(page).to have_error_message("Vos pièces jointes font plus de 15 ko au total")
        expect(usercontestsolution.content).not_to eq(newsolution2)
        expect(usercontestsolution.myfiles.count).to eq(1)
        expect(usercontestsolution.myfiles.first.file.filename.to_s).to eq(image1)
      end
    end
  end
end
