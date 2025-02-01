# -*- coding: utf-8 -*-
require "spec_helper"

describe "Contest pages", contest: true do

  subject { page }

  let(:admin) { FactoryGirl.create(:admin) }
  let(:user_with_rating_199) { FactoryGirl.create(:user, rating: 199) }
  let(:user_with_rating_200) { FactoryGirl.create(:user, rating: 200) }
  let(:user_participating1) { FactoryGirl.create(:user, rating: 250) }
  let(:user_participating2) { FactoryGirl.create(:user, rating: 251) }
  let(:user_participating3) { FactoryGirl.create(:user, rating: 252) }
  let(:user_participating4) { FactoryGirl.create(:user, rating: 253) }
  let(:user_participating5) { FactoryGirl.create(:user, rating: 254) }
  let!(:user_organizer) { FactoryGirl.create(:user, rating: 300) }
  
  let!(:contest) { FactoryGirl.create(:contest) }
  let!(:contestproblem1) { FactoryGirl.create(:contestproblem, contest: contest) }
  let!(:contestproblem2) { FactoryGirl.create(:contestproblem, contest: contest) }
  let!(:contestsolution11) { FactoryGirl.create(:contestsolution, contestproblem: contestproblem1, user: user_participating1, score: 7) }
  let!(:contestsolution12) { FactoryGirl.create(:contestsolution, contestproblem: contestproblem1, user: user_participating2, score: 6) }
  let!(:contestsolution13) { FactoryGirl.create(:contestsolution, contestproblem: contestproblem1, user: user_participating3, score: 5) }
  let!(:contestsolution14) { FactoryGirl.create(:contestsolution, contestproblem: contestproblem1, user: user_participating4, score: 5) }
  let!(:contestsolution15) { FactoryGirl.create(:contestsolution, contestproblem: contestproblem1, user: user_participating5, score: 7) }
  let!(:contestsolution21) { FactoryGirl.create(:contestsolution, contestproblem: contestproblem2, user: user_participating1, score: 7) }
  let!(:contestsolution22) { FactoryGirl.create(:contestsolution, contestproblem: contestproblem2, user: user_participating2, score: 7) }
  let!(:contestsolution23) { FactoryGirl.create(:contestsolution, contestproblem: contestproblem2, user: user_participating3, score: 6) }
  let!(:contestsolution24) { FactoryGirl.create(:contestsolution, contestproblem: contestproblem2, user: user_participating4, score: 2) }
  let!(:contestsolution25) { FactoryGirl.create(:contestsolution, contestproblem: contestproblem2, user: user_participating5, score: 0) }
  let!(:contestscore1) { FactoryGirl.create(:contestscore, contest: contest, user: user_participating1, rank: 1, score: 14) }
  let!(:contestscore2) { FactoryGirl.create(:contestscore, contest: contest, user: user_participating2, rank: 2, score: 13) }
  let!(:contestscore3) { FactoryGirl.create(:contestscore, contest: contest, user: user_participating3, rank: 3, score: 11) }
  let!(:contestscore4) { FactoryGirl.create(:contestscore, contest: contest, user: user_participating4, rank: 4, score: 7) }
  let!(:contestscore5) { FactoryGirl.create(:contestscore, contest: contest, user: user_participating5, rank: 4, score: 7) }
  
  let!(:contest_in_progress) { FactoryGirl.create(:contest, status: :in_progress) }
  let!(:contestproblem1_corrected) { FactoryGirl.create(:contestproblem, contest: contest_in_progress, status: :corrected) }
  let!(:contestproblem2_in_correction) { FactoryGirl.create(:contestproblem, contest: contest_in_progress, status: :in_correction) }
  let!(:contestproblem3_in_progress) { FactoryGirl.create(:contestproblem, contest: contest_in_progress, status: :in_progress) }
  let!(:contestproblem4_not_started_yet) { FactoryGirl.create(:contestproblem, contest: contest_in_progress, status: :not_started_yet) }
  
  let!(:offline_contest) { FactoryGirl.create(:contest, status: :in_construction) }
  let!(:offline_contestproblem) { FactoryGirl.create(:contestproblem, contest: offline_contest, status: :in_construction, start_time: DateTime.now + 1.day, end_time: DateTime.now + 2.days) }
  
  let(:newnumber) { 42 }
  let(:newdescription) { "Voici une toute nouvelle description" }
  let(:bronze_cutoff) { 11 }
  let(:silver_cutoff) { 13 }
  let(:gold_cutoff) { 14 }
  
  before do
    contest.organizers << user_organizer
    offline_contest.organizers << user_organizer
  end
  
  describe "user with rating 199" do
    before { sign_in user_with_rating_199 }
    
    describe "visits finished contest page" do    
      before { visit contest_path(contest) }
      
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
    end
  end
  
  describe "organizer" do
    before { sign_in user_organizer }
    
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
          expect(page).to have_success_message("Concours modifié.")
        end
      end
      
      describe "and tries to remove the description" do
        before do
          fill_in "MathInput", with: ""
          click_button "Modifier"
          offline_contest.reload
        end
        specify do
          expect(page).to have_error_message("Description doit être rempli(e)")
          expect(offline_contest.description).not_to eq("")
        end
      end
    end
    
    describe "visit cutoffs page" do
      before { visit cutoffs_contest_path(contest) }
      it { should have_selector("h1", text: "Seuils des médailles") }
      
      describe "and define cutoffs" do
        before do
          # Put wrong scores (to check they are re-computed correctly), as well as a fake score that should not exist
          contestscore1.update(score: 23, rank: 7)
          contestscore2.update(score: 23, rank: 7)
          contestscore3.update(score: 23, rank: 7)
          contestscore4.update(score: 23, rank: 7)
          contestscore5.destroy
          FactoryGirl.create(:contestscore, contest: contest, score: 23, rank: 7)
          fill_in "bronze_cutoff", with: bronze_cutoff
          fill_in "silver_cutoff", with: silver_cutoff
          fill_in "gold_cutoff", with: gold_cutoff
          click_button "Distribuer les médailles"
          contest.reload
          contestscore1.reload
          contestscore2.reload
          contestscore3.reload
          contestscore4.reload
        end
        let!(:contestscore5_new) { contest.contestscores.where(:user => user_participating5).first }
        specify do
          expect(contest.bronze_cutoff).to eq(bronze_cutoff)
          expect(contest.silver_cutoff).to eq(silver_cutoff)
          expect(contest.gold_cutoff).to eq(gold_cutoff)
          expect(contest.contestscores.count).to eq(5)
          expect(contestscore1.score).to eq(14)
          expect(contestscore2.score).to eq(13)
          expect(contestscore3.score).to eq(11)
          expect(contestscore4.score).to eq(7)
          expect(contestscore5_new.score).to eq(7)
          expect(contestscore1.rank).to eq(1)
          expect(contestscore2.rank).to eq(2)
          expect(contestscore3.rank).to eq(3)
          expect(contestscore4.rank).to eq(4)
          expect(contestscore5_new.rank).to eq(4)
          expect(contestscore1.gold_medal?).to eq(true)             # Gold medal for 14
          expect(contestscore2.silver_medal?).to eq(true)           # Silver medal for 13
          expect(contestscore3.bronze_medal?).to eq(true)           # Bronze medal for 11
          expect(contestscore4.no_medal?).to eq(true)               # No medal (7 = 5+2)
          expect(contestscore5_new.honourable_mention?).to eq(true) # Honourable mention (7 = 7+0)
          expect(page).to have_success_message("Les médailles ont été distribuées !")
        end
      end
      
      describe "and define cutoffs with negative bronze" do
        before do
          fill_in "bronze_cutoff", with: -2
          fill_in "silver_cutoff", with: silver_cutoff
          fill_in "gold_cutoff", with: gold_cutoff
          click_button "Distribuer les médailles"
        end
        let!(:contestscore5_new) { contest.contestscores.where(:user => user_participating5).first }
        specify do
          expect(page).to have_error_message("Seuil pour le bronze doit être supérieur ou égal à 0")
          expect(contest.bronze_cutoff).to eq(0)
          expect(contest.silver_cutoff).to eq(0)
          expect(contest.gold_cutoff).to eq(0)
        end
      end
    end
  end
  
  describe "admin" do
    before { sign_in admin }
     
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
          expect(page).to have_selector("h1", text: "Concours ##{newnumber}")
          expect(page).to have_content(newdescription)
        end
        
        describe "and tries to put it online without a problem" do
          before { click_link "Mettre en ligne" }
          it { should have_error_message("Un concours doit contenir au moins un problème !") }
        end
      end
      
      describe "and creates a new contest without number" do
        before do
          fill_in "MathInput", with: newdescription
          click_button "Créer"
        end
        it { should have_error_message("Numéro doit être rempli") }
      end
    end  
    
    describe "visits offline contest page" do
      before { visit contest_path(offline_contest) }
      specify do
        expect(page).to have_link("Modifier ce concours")
        expect(page).to have_link("Mettre en ligne")
        expect(page).to have_link("Supprimer ce concours")
        expect(page).to have_button("Ajouter") # To add an organizer
        expect { click_link "Supprimer ce concours" }.to change(Contest, :count).by(-1)
      end

      describe "and puts it online" do
        before do
          Category.create(:name => "Mathraining") # Will be used for the new subject
          click_link "Mettre en ligne"
          offline_contest.reload
          offline_contestproblem.reload
        end
        specify do
          expect(page).to have_success_message("Concours mis en ligne")
          expect(offline_contest.in_progress?).to eq(true)
          expect(offline_contestproblem.not_started_yet?).to eq(true)
          expect(Subject.order(:id).last.category.name).to eq("Mathraining")
          expect(Subject.order(:id).last.title).to eq("Concours ##{offline_contest.number}")
          expect(Subject.order(:id).last.contest).to eq(offline_contest)
        end
      end
      
      describe "and tries to put it online too late" do
        before do
          offline_contestproblem.update_attribute(:start_time, DateTime.now - 20.minutes)
          click_link "Mettre en ligne"
          offline_contest.reload
          offline_contestproblem.reload
        end
        specify do
          expect(page).to have_error_message("Un concours ne peut être mis en ligne moins d'une heure avant le premier problème.")
          expect(offline_contest.in_construction?).to eq(true)
          expect(offline_contestproblem.in_construction?).to eq(true)
        end
      end
      
      describe "and adds an organizer" do
        before do
          # Ensure that user_with_rating_200 appears in the list of possible organizers:
          user_with_rating_200.update_attribute(:last_connexion_date, DateTime.now.to_date)
          visit contest_path(offline_contest)
          select "#{user_with_rating_200.name} (200)", from: "user_id"
          click_button "Ajouter"
        end
        specify do
          expect(offline_contest.organizers.count).to eq(2)
          expect(offline_contest.organizers.exists?(user_with_rating_200.id)).to eq(true)
          expect(page).to have_link(user_with_rating_200.name, href: user_path(user_with_rating_200))
          expect(page).to have_link("supprimer", href: remove_organizer_contest_path(offline_contest, :user_id => user_organizer))
        end
      end
      
      specify { expect { click_link("supprimer", href: remove_organizer_contest_path(offline_contest, :user_id => user_organizer)) }.to change(offline_contest.organizers, :count).by(-1) }
    end
  end
end
