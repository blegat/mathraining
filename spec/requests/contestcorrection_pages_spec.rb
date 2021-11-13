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
      it do
        should have_selector("h1", text: "Problème ##{contestproblem_finished.number}")
        should have_no_link("Voir", :href => contestproblem_path(contestproblem_finished, :sol => officialsol_finished)) # We should not see it because it is non-public by default
        should have_link("Voir", :href => contestproblem_path(contestproblem_finished, :sol => usersol_finished))
      end
    end
    
    describe "visits an official solution without having reserved" do
      before { visit contestproblem_path(contestproblem_finished, :sol => officialsol_finished) }
      it do
        should have_selector("h3", text: "Solution officielle (non-publique)")
        should have_link("Modifier la solution")
        should have_button("Enregistrer (non-publique)", disabled: true) # Not reserved so disabled
        should have_button("Enregistrer (publique)", disabled: true) # Not reserved so disabled
        should have_button("Enregistrer (publique étoilée)", disabled: true) # Not reserved so disabled
      end
    end
    
    describe "visits an official solution after having reserved" do
      before do
        officialsol_finished.reservation = user_organizer.id
        officialsol_finished.save
        visit contestproblem_path(contestproblem_finished, :sol => officialsol_finished)
      end
      it do
        should have_content("Aucune solution étoilée")
        should have_link("Modifier la solution")
        should have_button("Enregistrer (non-publique)")
        should have_button("Enregistrer (publique)")
        should have_button("Enregistrer (publique étoilée)")
      end
      
      describe "and modifies it as a starred solution" do
        before do
          fill_in "MathInput", with: newcorrection
          click_button "Enregistrer (publique étoilée)"
          officialsol_finished.reload
          officialsol_finished.contestcorrection.reload
        end
        specify do
          expect(officialsol_finished.score).to eq(7)
          expect(officialsol_finished.star).to eq(true)
          expect(officialsol_finished.contestcorrection.content).to eq(newcorrection)
        end
        it do
          should have_no_content("Aucune solution étoilée")
          should have_link("Voir", :href => contestproblem_path(contestproblem_finished, :sol => officialsol_finished))
        end
      end
      
      describe "and modifies it as a bad solution" do
        before do
          fill_in "MathInput", with: newcorrection
          click_button "Enregistrer (non-publique)"
          officialsol_finished.reload
          officialsol_finished.contestcorrection.reload
        end
        specify do
          expect(officialsol_finished.score).to eq(0)
          expect(officialsol_finished.star).to eq(false)
          expect(officialsol_finished.contestcorrection.content).to eq(newcorrection)
        end
      end
      
      describe "and modifies it as a good non-starred solution" do
        before do
          fill_in "MathInput", with: newcorrection
          click_button "Enregistrer (publique)"
          officialsol_finished.reload
          officialsol_finished.contestcorrection.reload
        end
        specify do
          expect(officialsol_finished.score).to eq(7)
          expect(officialsol_finished.star).to eq(false)
          expect(officialsol_finished.contestcorrection.content).to eq(newcorrection)
        end
      end
    end
    
    describe "visits a user solution after having reserved" do
      before do
        usersol_finished.reservation = user_organizer.id
        usersol_finished.save
        visit contestproblem_path(contestproblem_finished, :sol => usersol_finished)
      end
      it do
        should have_selector("h3", text: "Solution de #{user_participating.name}")
        should have_content("- / 7")
        should have_link("Modifier la correction")
        should have_button("Enregistrer provisoirement")
        should have_button("Enregistrer")
        should have_button("Enregistrer et étoiler (si 7/7)")
      end
      
      describe "and marks it as wrong" do
        before do
          fill_in "MathInput", with: newcorrection
          fill_in "score", with: 2
          click_button "Enregistrer"
          usersol_finished.reload
          usersol_finished.contestcorrection.reload
        end
        specify do
          expect(usersol_finished.score).to eq(2)
          expect(usersol_finished.star).to eq(false)
          expect(usersol_finished.corrected).to eq(true)
          expect(usersol_finished.contestcorrection.content).to eq(newcorrection)
        end
        it do
          should have_no_link("Voir", :href => contestproblem_path(contestproblem_finished, :sol => usersol_finished)) # We should not see it anymore without javascript
          should have_content("2 / 7")
        end
      end
      
      describe "and marks it as correct without star" do
        before do
          fill_in "MathInput", with: newcorrection
          fill_in "score", with: 7
          click_button "Enregistrer"
          usersol_finished.reload
          usersol_finished.contestcorrection.reload
        end
        specify do
          expect(usersol_finished.score).to eq(7)
          expect(usersol_finished.star).to eq(false)
          expect(usersol_finished.contestcorrection.content).to eq(newcorrection)
        end
        it do
          should have_content("7 / 7")
          should have_content("Il faut au minimum une solution étoilée pour publier les résultats")
        end
      end
      
      describe "and marks it as correct with star" do
        before do
          fill_in "MathInput", with: newcorrection
          fill_in "score", with: 5 # Should be automatically set to 7
          click_button "Enregistrer et étoiler (si 7/7)"
          usersol_finished.reload
          usersol_finished.contestcorrection.reload
        end
        specify do
          expect(usersol_finished.score).to eq(7)
          expect(usersol_finished.star).to eq(true)
          expect(usersol_finished.contestcorrection.content).to eq(newcorrection)
        end
        it do
          should have_content("Le score a été mis automatiquement à 7/7 (car solution étoilée).")
          should have_content("7 / 7")
          should have_button("Publier les résultats")
        end
        
        describe "and publish the results" do
          before do
            click_button("Publier les résultats")
            contestproblem_finished.reload
          end
          specify do
            expect(contestproblem_finished.status).to eq(4)
            expect(contest.contestscores.count).to eq(1)
            expect(contest.contestscores.first.user).to eq(user_participating)
            expect(contest.contestscores.first.score).to eq(7)
            expect(contest.contestscores.first.rank).to eq(1)
            expect(contest.contestscores.first.medal).to eq(-1)
            expect(contestsubject.messages.count).to eq(1)
            expect(contestsubject.messages.first.user_id).to eq(0)
          end
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
          specify do
            expect(usersol_finished.score).to eq(7)
            expect(usersol_finished.star).to eq(true)
            expect(usersol_finished.contestcorrection.content).to eq(newcorrection)
          end
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
        specify do
          expect(usersol_finished.score).to eq(3)
          expect(usersol_finished.corrected).to eq(false)
          expect(usersol_finished.contestcorrection.content).to eq(newcorrection)
        end
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
        specify do
          expect(usersol_finished.score).to eq(-1)
          expect(usersol_finished.contestcorrection.content).to eq("-")
        end
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
        specify do
          expect(usersol_finished.score).to eq(-1)
          expect(usersol_finished.contestcorrection.content).to eq("-")
        end
      end
    end
    
    # TESTS THAT REQUIRE JAVASCRIPT
    describe "wants to modify the solution", :js => true do
      before do
        visit contestproblem_path(contestproblem_finished, :sol => usersol_finished)
        click_link("Modifier la correction")
        wait_for_ajax
      end
      it do
        should have_content("Cliquez ici pour réserver.")
        should have_button("button-reserve")
        should have_button("Enregistrer provisoirement", disabled: true)
        should have_button("Enregistrer", disabled: true)
        should have_button("Enregistrer et étoiler (si 7/7)", disabled: true)
      end
      
      describe "and does not want anymore" do
        before do
          click_button("Annuler")
          wait_for_ajax
        end
        specify { expect { click_button("Annuler") }.to raise_error(Capybara::Poltergeist::MouseEventFailed) } # Button should have disappeared
      end
      
      describe "and reserves it while somebody else reserved it" do
        before do
          usersol_finished.reservation = root.id
          usersol_finished.save
          click_button("button-reserve")
          wait_for_ajax
          usersol_finished.reload
        end
        it { should have_content("Réservé par #{root.name}.") }
        specify { expect(usersol_finished.reservation).to eq(root.id) }
      end
      
      describe "and reserves it" do
        before do
          click_button("button-reserve")
          wait_for_ajax
          usersol_finished.reload
        end
        it do
          should have_content("Cliquez ici pour annuler votre réservation.")
          should have_button("button-unreserve")
          should have_button("Enregistrer provisoirement")
          should have_button("Enregistrer")
          should have_button("Enregistrer et étoiler (si 7/7)")
        end
        specify { expect(usersol_finished.reservation).to eq(user_organizer.id) }
      
        describe "and unreserves it" do
          before do
            click_button("button-unreserve")
            wait_for_ajax
            usersol_finished.reload
          end
          it do
            should have_content("Cliquez ici pour réserver.")
            should have_button("button-reserve")
            should have_button("Enregistrer provisoirement", disabled: true)
            should have_button("Enregistrer", disabled: true)
            should have_button("Enregistrer et étoiler (si 7/7)", disabled: true)
          end
          specify { expect(usersol_finished.reservation).to eq(0) }
        end
      end
    end
  end
end
