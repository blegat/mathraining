# -*- coding: utf-8 -*-
require "spec_helper"

describe "Contest pages" do

  subject { page }

  let(:admin) { FactoryGirl.create(:admin) }
  let(:user_with_rating_199) { FactoryGirl.create(:user, rating: 199) }
  let(:user_with_rating_200) { FactoryGirl.create(:user, rating: 200) }
  let(:user_participating) { FactoryGirl.create(:user, rating: 250) }
  let!(:user_organizer) { FactoryGirl.create(:user, rating: 300) }
  
  let!(:category) { FactoryGirl.create(:category, name: "Mathraining") } # For the Forum subject
  
  let!(:contest) { FactoryGirl.create(:contest) }
  let!(:contestproblem) { FactoryGirl.create(:contestproblem, contest: contest) }
  let!(:contestsolution) { FactoryGirl.create(:contestsolution, contestproblem: contestproblem, user: user_participating, score: 7) }
  let!(:contestscore) { FactoryGirl.create(:contestscore, contest: contest, user: user_participating, rank: 1, score: 7, medal: -1) }
  
  let!(:offline_contest) { FactoryGirl.create(:contest, status: 0) }
  let!(:offline_contestproblem) { FactoryGirl.create(:contestproblem, contest: offline_contest, status: 0, start_time: DateTime.now + 1.day, end_time: DateTime.now + 2.days) }
  
  let(:newnumber) { 42 }
  let(:newdescription) { "Voici une toute nouvelle description" }
  let(:bronze_cutoff) { 7 }
  let(:silver_cutoff) { 14 }
  let(:gold_cutoff) { 21 }
  
  before do
    Contestorganization.create(:contest => contest, :user => user_organizer)
    Contestorganization.create(:contest => offline_contest, :user => user_organizer)
  end
  
  describe "visitor" do
    describe "visits contests page" do
      before { visit contests_path }
      it do
        should have_selector("h1", text: "Concours")
        should have_selector("h3", text: "Concours ##{contest.number}")
        should have_no_selector("h3", text: "Concours ##{offline_contest.number}")
        should have_selector("div", text: "Les problèmes des concours sont accessibles par tous, mais il est nécessaire d'avoir au moins 200 points pour y participer.")
      end
    end
    
    describe "visits one contest page" do
      before { visit contest_path(contest) }
      it do
        should have_content("Concours ##{contest.number}") # Not h1: not correctly detected because of "Suivre ce concours"
        should have_selector("h3", text: "Problème ##{contestproblem.number}")
        should have_content(contestproblem.statement)
        should have_content(contestproblem.origin)
        should have_link("Classement final", href: contest_path(contest, :tab => 1))
        should have_link("Statistiques", href: contest_path(contest, :tab => 2))
      end
      
      describe "and visits the rankings" do
        before { click_link "Classement final" }
        it { should have_content("Le classement n'est visible que par les utilisateurs connectés.") }
      end
      
      describe "and visits the statistics" do
        before { click_link("Statistiques", href: contest_path(contest, :tab => 2)) }
        it { should have_selector("h3", text: "Distribution des scores") }
      end
    end
  end
  
  describe "user with rating 199" do
    before { sign_in user_with_rating_199 }
    
    describe "visits one contest page" do    
      before { visit contest_path(contest) }
      it do
        should have_content("Concours ##{contest.number}") # Not h1: not correctly detected because of "Suivre ce concours"
        should have_link("link_follow")
      end
        
      describe "and visits the rankings" do
        before { click_link "Classement final" }
        it { should have_no_content("Le classement n'est visible que par les utilisateurs connectés.") }
      end
      
      describe "and visits the statistics" do
        before { click_link("Statistiques", href: contest_path(contest, :tab => 2)) }
        it { should have_selector("h3", text: "Distribution des scores") }
      end
      
      describe "and follows the contest" do
        before { click_link("link_follow") }
        specify do
          expect(page).to have_success_message("Vous recevrez dorénavant un e-mail de rappel un jour avant la publication de chaque problème de ce concours.")
          expect(page).to have_link("link_unfollow")
          expect(user_with_rating_199.followed_contests.exists?(contest.id)).to eq(true)
        end
        
        describe "and unfollows the contest" do
          before { click_link("link_unfollow") }
          specify do
            expect(page).to have_success_message("Vous ne recevrez maintenant plus d'e-mail concernant ce concours.")
            expect(page).to have_link("link_follow")
            expect(user_with_rating_199.followed_contests.exists?(contest.id)).to eq(false)
          end
        end
      end
      
      describe "try to unfollow a non-existing contest" do
        before { visit remove_followingcontest_path(:contest_id => 6543) }
        it { should have_content(error_access_refused) }
      end
    end
    
    describe "tries to visit an offline contest page" do
      before { visit contest_path(offline_contest) }
      it { should have_content(error_access_refused) }
    end
  end
  
  describe "organizer" do
    before { sign_in user_organizer }
    
    describe "visits contest page" do
      before { visit contest_path(contest) }
      it { should have_link("Définir les médailles", href: contest_cutoffs_path(contest)) }
    end
    
    describe "visits offline contest page" do
      before { visit contest_path(offline_contest) }
      it do
        should have_link("Modifier ce concours")
        should have_no_link("Mettre ce concours en ligne")
        should have_no_link("Supprimer ce concours")
      end
    end
    
    describe "visits contest edit page" do
      before { visit edit_contest_path(offline_contest) }
      it { should have_selector("h1", text: "Modifier") }
           
      describe "and modifies it" do
        before do
          fill_in "Numéro", with: newnumber
          fill_in "MathInput", with: newdescription
          check "Attribuer des médailles au terme de ce concours"
          click_button "Modifier"
          offline_contest.reload
        end
        specify do
          expect(offline_contest.number).to eq(newnumber)
          expect(offline_contest.description).to eq(newdescription)
          expect(offline_contest.medal).to eq(true)
          expect(page).to have_content("Concours modifié.")
        end
      end
    end
    
    describe "visit cutoffs page" do
      before { visit contest_cutoffs_path(contest) }
      it { should have_selector("h1", text: "Seuils des médailles") }
      
      describe "and define cutoffs" do
        before do
          fill_in "bronze_cutoff", with: bronze_cutoff
          fill_in "silver_cutoff", with: silver_cutoff
          fill_in "gold_cutoff", with: gold_cutoff
          click_button "Distribuer les médailles"
          contest.reload
          contestscore.reload
        end
        specify do
          expect(contest.bronze_cutoff).to eq(bronze_cutoff)
          expect(contest.silver_cutoff).to eq(silver_cutoff)
          expect(contest.gold_cutoff).to eq(gold_cutoff)
          expect(contestscore.medal).to eq(2) # Bronze medal for score = 7
          expect(page).to have_success_message("Les médailles ont été distribuées !")
        end
      end
    end
  end
  
  describe "admin" do
    before { sign_in admin }

    describe "visits contests page" do
      before { visit contests_path }
      it { should have_link("Ajouter un concours", href: new_contest_path) }
    end
     
    describe "visits contest creation page" do
      before { visit new_contest_path }
      it { should have_selector("h1", text: "Créer un concours") }
       
      describe "and creates a new contest" do
        before do
          fill_in "Numéro", with: newnumber
          fill_in "MathInput", with: newdescription
          check "Attribuer des médailles au terme de ce concours"
          click_button "Créer"
        end
        specify do
          expect(Contest.order(:id).last.number).to eq(newnumber)
          expect(Contest.order(:id).last.description).to eq(newdescription)
          expect(Contest.order(:id).last.medal).to eq(true)
          expect(page).to have_success_message("Concours ajouté.")
          expect(page).to have_content("Concours ##{newnumber}")
          expect(page).to have_content(newdescription)
        end
        
        describe "and tries to put it online without a problem" do
          before { click_link "Mettre ce concours en ligne" }
          it { should have_error_message("Un concours doit contenir au moins un problème !") }
        end
      end
    end  
    
    describe "visits online contest page" do
      before { visit contest_path(contest) }
      it do
        should have_link("Modifier ce concours")
        should have_no_link("Mettre ce concours en ligne")
        should have_no_link("Supprimer ce concours")
      end
    end
    
    describe "visits offline contest page" do
      before { visit contest_path(offline_contest) }
      specify do
        expect(page).to have_link("Modifier ce concours")
        expect(page).to have_link("Mettre ce concours en ligne")
        expect(page).to have_link("Supprimer ce concours")
        expect(page).to have_button("Ajouter") # To add an organizer
        expect { click_link "Supprimer ce concours" }.to change(Contest, :count).by(-1)
      end

      describe "and puts it online" do
        before do
          click_link "Mettre ce concours en ligne"
          offline_contest.reload
          offline_contestproblem.reload
        end
        specify do
          expect(page).to have_success_message("Concours mis en ligne")
          expect(offline_contest.status).to eq(1)
          expect(offline_contestproblem.status).to eq(1)
          expect(Subject.order(:id).last.category).to eq(category)
          expect(Subject.order(:id).last.title).to eq("Concours ##{offline_contest.number}")
          expect(Subject.order(:id).last.contest).to eq(offline_contest)
        end
      end
      
      describe "and tries to put it online too late" do
        before do
          offline_contestproblem.start_time = DateTime.now - 20.minutes
          offline_contestproblem.save
          click_link "Mettre ce concours en ligne"
          offline_contest.reload
          offline_contestproblem.reload
        end
        specify do
          expect(page).to have_error_message("Un concours ne peut être mis en ligne moins d'une heure avant le premier problème.")
          expect(offline_contest.status).to eq(0)
          expect(offline_contestproblem.status).to eq(0)
        end
      end
      
      describe "and adds an organizer" do
        before do
          # Ensure that user_with_rating_200 appears in the list of possible organizers:
          user_with_rating_200.last_connexion = DateTime.now.to_date
          user_with_rating_200.save
          visit contest_path(offline_contest)
          select "#{user_with_rating_200.name} (200)", from: "contestorganization_user_id"
          click_button "Ajouter"
        end
        specify do
          expect(offline_contest.organizers.count).to eq(2)
          expect(Contestorganization.order(:id).last.contest).to eq(offline_contest)
          expect(Contestorganization.order(:id).last.user).to eq(user_with_rating_200)
          expect(page).to have_link(user_with_rating_200.name, href: user_path(user_with_rating_200))
          expect(page).to have_link("supprimer", href: contestorganization_path(Contestorganization.last))
        end
      end
      
      let!(:organization_to_delete) { Contestorganization.where(:contest => offline_contest, :user => user_organizer).first }
      specify { expect { click_link("supprimer", href: contestorganization_path(organization_to_delete)) }.to change(Contestorganization, :count).by(-1) }
      
      describe "deletes an organizer that was deleted by someone else" do
        before do
          id = organization_to_delete.id
          organization_to_delete.destroy
          click_link("supprimer", href: contestorganization_path(id))
        end
        it { should have_content(error_access_refused) }
      end
    end
  end
end
