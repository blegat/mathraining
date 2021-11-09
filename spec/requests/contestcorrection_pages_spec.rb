# -*- coding: utf-8 -*-
require "spec_helper"

describe "Contestcorrection pages" do

  subject { page }
  
  let(:datetime_before) { DateTime.now - 2.hours }
  let(:datetime_before2) { DateTime.now - 1.hour }
  let(:datetime_after) { DateTime.now + 1.hour }
  let(:datetime_after2) { DateTime.now + 2.hours }

  let(:root) { FactoryGirl.create(:root) }
  let(:user_participating) { FactoryGirl.create(:user, rating: 200) }
  let!(:user_organizer) { FactoryGirl.create(:user, rating: 300) }
  
  let!(:contest) { FactoryGirl.create(:contest, status: 1) }
  let!(:contestsubject) { FactoryGirl.create(:subject, contest: contest, user_id: 0) }
  
  let!(:contestproblem_finished) { FactoryGirl.create(:contestproblem, contest: contest, number: 1, start_time: datetime_before, end_time: datetime_before2, status: 3) }
  
  let(:officialsol_finished) { contestproblem_finished.contestsolutions.where(:official => true).first }
  let!(:usersol_finished) { FactoryGirl.create(:contestsolution, contestproblem: contestproblem_finished, user: user_participating) }
  
  let!(:newcorrection) { "Voici une correction spontanée." }
  let!(:newcorrection2) { "Voici une nouvelle correction." }
  
  before do
    Contestorganization.create(:contest => contest, :user => user_organizer)
  end
  
  describe "organizer" do
    before { sign_in user_organizer }

    describe "visits a finished contestproblem page" do
      before { visit contestproblem_path(contestproblem_finished) }
      it { should have_selector("h1", text: "Problème ##{contestproblem_finished.number}") }
      it { should_not have_link("Voir", :href => contestproblem_path(contestproblem_finished, :sol => officialsol_finished)) } # We should not see it because it is non-public by default
      it { should have_link("Voir", :href => contestproblem_path(contestproblem_finished, :sol => usersol_finished)) }
    end
    
    describe "visits an official solution without having reserved" do
      before { visit contestproblem_path(contestproblem_finished, :sol => officialsol_finished) }
      it { should have_selector("h3", text: "Solution officielle (non-publique)") }
      it { should have_link("Modifier la solution") }
      it { should have_button("Enregistrer (publique)", disabled: true) } # Not reserved so disabled
    end
    
    describe "visits an official solution after having reserved" do
      before do
        officialsol_finished.reservation = user_organizer.id
        officialsol_finished.save
        visit contestproblem_path(contestproblem_finished, :sol => officialsol_finished)
      end
      it { should have_content("Aucune solution étoilée") }
      it { should have_link("Modifier la solution") }
      it { should have_button("Enregistrer (non-publique)") }
      it { should have_button("Enregistrer (publique)") }
      it { should have_button("Enregistrer (publique étoilée)") }
      
      describe "and modifies it as a starred solution" do
        before do
          fill_in "MathInput", with: newcorrection
          click_button "Enregistrer (publique étoilée)"
          officialsol_finished.reload
          officialsol_finished.contestcorrection.reload
        end
        specify { expect(officialsol_finished.score).to eq(7) }
        specify { expect(officialsol_finished.star).to eq(true) }
        specify { expect(officialsol_finished.contestcorrection.content).to eq(newcorrection) }
        it { should_not have_content("Aucune solution étoilée") }
        it { should have_link("Voir", :href => contestproblem_path(contestproblem_finished, :sol => officialsol_finished)) }
      end
      
      describe "and modifies it as a bad solution" do
        before do
          fill_in "MathInput", with: newcorrection
          click_button "Enregistrer (non-publique)"
          officialsol_finished.reload
          officialsol_finished.contestcorrection.reload
        end
        specify { expect(officialsol_finished.score).to eq(0) }
        specify { expect(officialsol_finished.star).to eq(false) }
        specify { expect(officialsol_finished.contestcorrection.content).to eq(newcorrection) }
      end
      
      describe "and modifies it as a good non-starred solution" do
        before do
          fill_in "MathInput", with: newcorrection
          click_button "Enregistrer (publique)"
          officialsol_finished.reload
          officialsol_finished.contestcorrection.reload
        end
        specify { expect(officialsol_finished.score).to eq(7) }
        specify { expect(officialsol_finished.star).to eq(false) }
        specify { expect(officialsol_finished.contestcorrection.content).to eq(newcorrection) }
      end
    end
    
    describe "visits a user solution after having reserved" do
      before do
        usersol_finished.reservation = user_organizer.id
        usersol_finished.save
        visit contestproblem_path(contestproblem_finished, :sol => usersol_finished)
      end
      it { should have_selector("h3", text: "Solution de #{user_participating.name}") }
      it { should have_content("- / 7") }
      it { should have_link("Modifier la correction") }
      it { should have_button("Enregistrer provisoirement") }
      it { should have_button("Enregistrer") }
      it { should have_button("Enregistrer et étoiler (si 7/7)") }
      
      describe "and marks it as wrong" do
        before do
          fill_in "MathInput", with: newcorrection
          fill_in "score", with: 2
          click_button "Enregistrer"
          usersol_finished.reload
          usersol_finished.contestcorrection.reload
        end
        specify { expect(usersol_finished.score).to eq(2) }
        specify { expect(usersol_finished.star).to eq(false) }
        specify { expect(usersol_finished.corrected).to eq(true) }
        specify { expect(usersol_finished.contestcorrection.content).to eq(newcorrection) }
        it { should_not have_link("Voir", :href => contestproblem_path(contestproblem_finished, :sol => usersol_finished)) } # We should not see it anymore without javascript
        it { should have_content("2 / 7") }
      end
      
      describe "and marks it as correct without star" do
        before do
          fill_in "MathInput", with: newcorrection
          fill_in "score", with: 7
          click_button "Enregistrer"
          usersol_finished.reload
          usersol_finished.contestcorrection.reload
        end
        specify { expect(usersol_finished.score).to eq(7) }
        specify { expect(usersol_finished.star).to eq(false) }
        specify { expect(usersol_finished.contestcorrection.content).to eq(newcorrection) }
        it { should have_content("7 / 7") }
        it { should have_content("Il faut au minimum une solution étoilée pour publier les résultats") }
      end
      
      describe "and marks it as correct with star" do
        before do
          fill_in "MathInput", with: newcorrection
          fill_in "score", with: 5 # Should be automatically set to 7
          click_button "Enregistrer et étoiler (si 7/7)"
          usersol_finished.reload
          usersol_finished.contestcorrection.reload
        end
        it { should have_content("Le score a été mis automatiquement à 7/7 (car solution étoilée).") }
        specify { expect(usersol_finished.score).to eq(7) }
        specify { expect(usersol_finished.star).to eq(true) }
        specify { expect(usersol_finished.contestcorrection.content).to eq(newcorrection) }
        it { should have_content("7 / 7") }
        it { should have_button("Publier les résultats") }
        
        describe "and publish the results" do
          before do
            click_button("Publier les résultats")
            contestproblem_finished.reload
          end
          specify { expect(contestproblem_finished.status).to eq(4) }
          specify { expect(contest.contestscores.count).to eq(1) }
          specify { expect(contest.contestscores.first.user).to eq(user_participating) }
          specify { expect(contest.contestscores.first.score).to eq(7) }
          specify { expect(contest.contestscores.first.rank).to eq(1) }
          specify { expect(contest.contestscores.first.medal).to eq(-1) }
          specify { expect(contestsubject.messages.count).to eq(1) }
          specify { expect(contestsubject.messages.first.user_id).to eq(0) }
        end
        
        describe "and tries to modify it after results were published" do
          before do
            # Need to reserve again:
            usersol_finished.reservation = user_organizer.id
            usersol_finished.save
            visit contestproblem_path(contestproblem_finished, :sol => usersol_finished)
            # Simulate publication of corrections by somebody else in the meanwhile:
            contestproblem_finished.status = 4
            contestproblem_finished.save
            # Tries to modify the correction (too late)
            fill_in "MathInput", with: newcorrection2
            click_button "Enregistrer"
            usersol_finished.reload
            usersol_finished.contestcorrection.reload
          end
          it { should have_content("Vous ne pouvez pas modifier cette correction.") }
          specify { expect(usersol_finished.score).to eq(7) }
          specify { expect(usersol_finished.star).to eq(true) }
          specify { expect(usersol_finished.contestcorrection.content).to eq(newcorrection) }
        end
      end
      
      describe "and does a temporary correction" do
        before do
          fill_in "MathInput", with: newcorrection
          fill_in "score", with: 3
          click_button "Enregistrer provisoirement"
          usersol_finished.reload
          usersol_finished.contestcorrection.reload
        end
        specify { expect(usersol_finished.score).to eq(3) }
        specify { expect(usersol_finished.corrected).to eq(false) }
        specify { expect(usersol_finished.contestcorrection.content).to eq(newcorrection) }
        it { should have_content("3 / 7") }
      end
      
      describe "and writes an empty correction" do
        before do
          fill_in "MathInput", with: ""
          fill_in "score", with: 6
          click_button "Enregistrer et étoiler (si 7/7)"
          usersol_finished.reload
          usersol_finished.contestcorrection.reload
        end
        it { should have_content("Votre correction est vide.") }
        specify { expect(usersol_finished.score).to eq(-1) }
        specify { expect(usersol_finished.contestcorrection.content).to eq("-") }
      end

      describe "and hacked the system (he did not reserve)" do
        before do
          usersol_finished.reservation = 0
          usersol_finished.save
          fill_in "MathInput", with: newcorrection
          fill_in "score", with: 4
          click_button "Enregistrer"
          usersol_finished.reload
          usersol_finished.contestcorrection.reload
        end
        it { should have_content("Vous n'avez pas réservé.") }
        specify { expect(usersol_finished.score).to eq(-1) }
        specify { expect(usersol_finished.contestcorrection.content).to eq("-") }
      end
    end
  end
end
