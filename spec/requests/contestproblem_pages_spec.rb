# -*- coding: utf-8 -*-
require "spec_helper"

describe "Contestproblem pages", contestproblem: true do

  subject { page }
  
  let!(:past_year) { DateTime.now.year-2 }
  let!(:future_year) { DateTime.now.year+2 }
  let(:stringtimepast) { "01/01/#{past_year} 10:00" }
  let(:stringtimenotexact) { "01/01/#{future_year} 09:23" }
  let(:stringtime1) { "01/01/#{future_year} 10:00" }
  let(:stringtime2) { "02/01/#{future_year} 10:00" }
  let(:stringtime3) { "03/01/#{future_year} 10:00" }
  let(:stringtime4) { "04/01/#{future_year} 10:00" }
  let(:stringtime5) { "05/01/#{future_year} 10:00" }
  let(:stringtime6) { "06/01/#{future_year} 10:00" }
  let(:datetimepast) { Time.zone.parse(stringtimepast).to_datetime }
  let(:datetimenotexact) { Time.zone.parse(stringtimenotexact).to_datetime }
  let(:datetime1) { Time.zone.parse(stringtime1).to_datetime }
  let(:datetime2) { Time.zone.parse(stringtime2).to_datetime }
  let(:datetime3) { Time.zone.parse(stringtime3).to_datetime }
  let(:datetime4) { Time.zone.parse(stringtime4).to_datetime }
  let(:datetime5) { Time.zone.parse(stringtime5).to_datetime }
  let(:datetime6) { Time.zone.parse(stringtime6).to_datetime }

  let(:root) { FactoryGirl.create(:root) }
  let(:user_with_rating_199) { FactoryGirl.create(:user, rating: 199) }
  let(:user_with_rating_200) { FactoryGirl.create(:user, rating: 200) }
  let(:user_participating) { FactoryGirl.create(:user, rating: 250) }
  let!(:user_organizer) { FactoryGirl.create(:user, rating: 300) }

  let!(:contest) { FactoryGirl.create(:contest) }
  let!(:contestproblem) { FactoryGirl.create(:contestproblem, contest: contest, number: 1) }
  let!(:contestsolution) { FactoryGirl.create(:contestsolution, contestproblem: contestproblem, user: user_participating, score: 7) }
  let!(:contestscore) { FactoryGirl.create(:contestscore, contest: contest, user: user_participating, rank: 1, score: 7) }
  
  let!(:offline_contest) { FactoryGirl.create(:contest, status: :in_construction) }
  let!(:offline_contestproblem) { FactoryGirl.create(:contestproblem, contest: offline_contest, number: 1, status: :in_construction, start_time: datetime2, end_time: datetime4) }
  
  let(:newstatement) { "Nouvel énoncé de problème" }
  let(:neworigin) { "Nouvelle origine de problème" }
  
  before do
    contest.organizers << user_organizer
    offline_contest.organizers << user_organizer
  end
  
  describe "user with rating 199" do
    before { sign_in user_with_rating_199 }

    describe "visits one contestproblem page" do
      before { visit contestproblem_path(contestproblem) }
      it { should have_selector("h1", text: "Problème ##{contestproblem.number}") }
    end
  end
  
  describe "organizer" do
    before { sign_in user_organizer }
    
    describe "visits offline contestproblem page" do
      before { visit contestproblem_path(offline_contestproblem) }
      specify do
        expect(page).to have_selector("h1", text: "Problème ##{offline_contestproblem.number}")
        expect(page).to have_link("Modifier ce problème", href: edit_contestproblem_path(offline_contest))
        expect(page).to have_link("Supprimer ce problème")
        expect { click_link "Supprimer ce problème" }.to change(Contestproblem, :count).by(-1)
      end
    end
    
    describe "visits contestproblem creation page" do
      before { visit new_contest_contestproblem_path(offline_contest) }
      it { should have_selector("h1", text: "Ajouter un problème") }
      
      describe "and creates a problem" do
        before do
          fill_in "MathInput", with: newstatement
          fill_in "Origine", with: neworigin
          fill_in "Parution du problème", with: stringtime3
          fill_in "Date limite pour l'envoi des solutions", with: stringtime5
          click_button "Ajouter"
        end
        let!(:newcontestproblem) {offline_contest.contestproblems.order(:id).last}
        specify do
          expect(page).to have_success_message("Problème ajouté")
          expect(offline_contest.contestproblems.count).to eq(2)
          expect(newcontestproblem.number).to eq(2)
          expect(newcontestproblem.statement).to eq(newstatement)
          expect(newcontestproblem.origin).to eq(neworigin)
          expect(newcontestproblem.start_time).to eq(datetime3)
          expect(newcontestproblem.end_time).to eq(datetime5)
        end
      end
      
      describe "and creates a problem with empty statement" do
        before do
          fill_in "MathInput", with: ""
          fill_in "Origine", with: neworigin
          fill_in "Parution du problème", with: stringtime3
          fill_in "Date limite pour l'envoi des solutions", with: stringtime5
          click_button "Ajouter"
          offline_contestproblem.reload
        end
        let!(:newcontestproblem) {offline_contest.contestproblems.order(:id).last}
        specify do
          expect(page).to have_error_message("Énoncé doit être rempli")
          expect(offline_contest.contestproblems.count).to eq(1)
        end
      end
      
      describe "and creates a problem before the first one" do
        before do
          fill_in "MathInput", with: newstatement
          fill_in "Origine", with: neworigin
          fill_in "Parution du problème", with: stringtime1
          fill_in "Date limite pour l'envoi des solutions", with: stringtime3
          click_button "Ajouter"
          offline_contestproblem.reload
        end
        let!(:newcontestproblem) {offline_contest.contestproblems.order(:id).last}
        specify do
          expect(page).to have_success_message("Problème ajouté")
          expect(offline_contest.contestproblems.count).to eq(2)
          expect(newcontestproblem.number).to eq(1)
          expect(offline_contestproblem.number).to eq(2)
        end
      end
      
      describe "and creates a problem with same dates" do
        before do
          fill_in "MathInput", with: newstatement
          fill_in "Origine", with: neworigin
          fill_in "Parution du problème", with: stringtime3
          fill_in "Date limite pour l'envoi des solutions", with: stringtime3
          click_button "Ajouter"
        end
        specify do
          expect(page).to have_error_message("La deuxième date doit être strictement après la première date.")
          expect(offline_contest.contestproblems.count).to eq(1)
        end
      end
      
      describe "and creates a problem with first date in the past" do
        before do
          fill_in "MathInput", with: newstatement
          fill_in "Origine", with: neworigin
          fill_in "Parution du problème", with: stringtimepast
          fill_in "Date limite pour l'envoi des solutions", with: stringtime3
          click_button "Ajouter"
        end
        specify do
          expect(page).to have_error_message("La première date ne peut pas être dans le passé.")
          expect(offline_contest.contestproblems.count).to eq(1)
        end
      end
      
      describe "and creates a problem with second date in the past" do
        before do
          fill_in "MathInput", with: newstatement
          fill_in "Origine", with: neworigin
          fill_in "Parution du problème", with: stringtime3
          fill_in "Date limite pour l'envoi des solutions", with: stringtimepast
          click_button "Ajouter"
        end
        specify do
          expect(page).to have_error_message("La deuxième date ne peut pas être dans le passé.")
          expect(offline_contest.contestproblems.count).to eq(1)
        end
      end
      
      describe "and creates a problem with first date not exact" do
        before do
          fill_in "MathInput", with: newstatement
          fill_in "Origine", with: neworigin
          fill_in "Parution du problème", with: stringtimenotexact
          fill_in "Date limite pour l'envoi des solutions", with: stringtime3
          click_button "Ajouter"
        end
        specify do
          expect(page).to have_error_message("La première date doit être à une heure pile.")
          expect(offline_contest.contestproblems.count).to eq(1)
        end
      end
      
      describe "and creates a problem without second date" do
        before do
          fill_in "MathInput", with: newstatement
          fill_in "Origine", with: neworigin
          fill_in "Parution du problème", with: stringtime3
          click_button "Ajouter"
        end
        specify do
          expect(page).to have_error_message("Les deux dates doivent être définies.")
          expect(offline_contest.contestproblems.count).to eq(1)
        end
      end
    end
    
    describe "visits contestproblem edit page" do
      before { visit edit_contestproblem_path(offline_contestproblem) }
      it { should have_selector("h1", text: "Modifier") }
      
      describe "and modifies it" do
        before do
          fill_in "MathInput", with: newstatement
          fill_in "Origine", with: neworigin
          fill_in "Parution du problème", with: stringtime3
          fill_in "Date limite pour l'envoi des solutions", with: stringtime5
          click_button "Modifier"
          offline_contestproblem.reload
        end
        specify do
          expect(page).to have_success_message("Problème modifié")
          expect(offline_contestproblem.number).to eq(1)
          expect(offline_contestproblem.statement).to eq(newstatement)
          expect(offline_contestproblem.origin).to eq(neworigin)
          expect(offline_contestproblem.start_time).to eq(datetime3)
          expect(offline_contestproblem.end_time).to eq(datetime5)
        end
      end
      
      describe "and modifies it with empty statement" do
        before do
          fill_in "MathInput", with: ""
          fill_in "Origine", with: neworigin
          fill_in "Parution du problème", with: stringtime3
          fill_in "Date limite pour l'envoi des solutions", with: stringtime5
          click_button "Modifier"
          offline_contestproblem.reload
        end
        specify do
          expect(page).to have_error_message("Énoncé doit être rempli")
          expect(offline_contestproblem.number).to eq(1)
          expect(offline_contestproblem.origin).not_to eq(neworigin)
          expect(offline_contestproblem.start_time).not_to eq(datetime3)
          expect(offline_contestproblem.end_time).not_to eq(datetime5)
        end
      end
      
      describe "and modifies it with second date before the first date" do
        before do
          fill_in "MathInput", with: newstatement
          fill_in "Origine", with: neworigin
          fill_in "Parution du problème", with: stringtime5
          fill_in "Date limite pour l'envoi des solutions", with: stringtime3
          click_button "Modifier"
          offline_contestproblem.reload
        end
        specify do
          expect(page).to have_error_message("La deuxième date doit être strictement après la première date.")
          expect(offline_contestproblem.number).to eq(1)
          expect(offline_contestproblem.statement).not_to eq(newstatement)
          expect(offline_contestproblem.origin).not_to eq(neworigin)
          expect(offline_contestproblem.start_time).not_to eq(datetime5)
          expect(offline_contestproblem.end_time).not_to eq(datetime3)
        end
      end
    end
    
    describe "visits contestproblem edit page for a problem that started" do
      before do
        offline_contest.in_progress!
        offline_contestproblem.in_progress!
        visit edit_contestproblem_path(offline_contestproblem)
      end
      it do
        should have_selector("h1", text: "Modifier")
        should have_field("Parution du problème", disabled: true)
      end
      
      describe "and modifies it" do
        before do
          fill_in "MathInput", with: newstatement
          fill_in "Origine", with: neworigin
          fill_in "Date limite pour l'envoi des solutions", with: stringtime5
          click_button "Modifier"
          offline_contestproblem.reload
        end
        specify do
          expect(page).to have_success_message("Problème modifié")
          expect(offline_contestproblem.statement).to eq(newstatement)
          expect(offline_contestproblem.start_time).to eq(datetime2)
          expect(offline_contestproblem.end_time).to eq(datetime5)
        end
      end
    end
    
    describe "visits contestproblem edit page for a problem that ended" do
      before do
        offline_contest.in_progress!
        offline_contestproblem.in_correction!
        visit edit_contestproblem_path(offline_contestproblem)
      end
      it do
        should have_selector("h1", text: "Modifier")
        should have_field("Parution du problème", disabled: true)
        should have_field("Date limite pour l'envoi des solutions", disabled: true)
      end
      
      describe "and modifies it" do
        before do
          fill_in "MathInput", with: newstatement
          fill_in "Origine", with: neworigin
          click_button "Modifier"
          offline_contestproblem.reload
        end
        specify do
          expect(page).to have_success_message("Problème modifié")
          expect(offline_contestproblem.statement).to eq(newstatement)
          expect(offline_contestproblem.start_time).to eq(datetime2)
          expect(offline_contestproblem.end_time).to eq(datetime4)
        end
      end
    end
  end
  
  describe "root" do
    before { sign_in root }
    
    describe "visits online contestproblem page" do
      before { visit contestproblem_path(contestproblem) }
      it do
        should have_selector("h1", text: "Problème ##{contestproblem.number}")
        should have_link("Autoriser nouvelles corrections")
      end
      
      describe "and authorizes new corrections" do
        before do
          click_link "Autoriser nouvelles corrections"
          contestproblem.reload
        end
        specify do
          expect(page).to have_success_message("Les organisateurs peuvent à présent modifier leurs corrections.")
          expect(page).to have_link("Stopper nouvelles corrections")
          expect(contestproblem.in_recorrection?).to eq(true)
        end
        
        describe "and unauthorizes them" do
          before do
            click_link "Stopper nouvelles corrections"
            contestproblem.reload
          end
          specify do
            expect(page).to have_success_message("Les organisateurs ne peuvent plus modifier leurs corrections.")
            expect(contestproblem.corrected?).to eq(true)
          end
        end
      end
    end
  end
end
