require "spec_helper"

describe ContestsHelper, type: :helper, contest: true do

  include ContestsHelper

  describe "forum messages" do
    let!(:user1) { FactoryBot.create(:user, last_name: "Albert") } # NB: We order organizers by last names in messages
    let!(:user2) { FactoryBot.create(:user, last_name: "Boulanger") }
    let!(:user3) { FactoryBot.create(:user, last_name: "Collard") }
    let!(:contest) { FactoryBot.create(:contest) }
    let!(:contestproblem1) { FactoryBot.create(:contestproblem, number: 1) }
    let!(:contestproblem2) { FactoryBot.create(:contestproblem, number: 2) }
    let!(:contestproblem3) { FactoryBot.create(:contestproblem, number: 3) }
    
    describe "new contest message" do
      describe "with one organizer and one problem" do
        before do
          contest.update_attribute(:medal, true)
          contest.organizers << user1
          contestproblem1.update_attribute(:contest, contest)
          contestproblem1.update_attribute(:start_time, Time.zone.parse('27-11-2021 13:00:00'))
        end
        it do
          forum_message = get_new_contest_forum_message(contest)
          expect(forum_message).to include("[url=#{contest_path(contest)}]Concours ##{contest.number}[/url]")
          expect(forum_message).to include("organisé par [b]#{user1.name}[/b], vient d'être mis en ligne")
          expect(forum_message).to include("Il comporte [b]1 problème[/b] et démarrera le [b]27 novembre 2021[/b]")
          expect(forum_message).to include("Des médailles et mentions honorables seront attribuées à la fin de ce concours.")
        end
      end
      
      describe "with three organizers and two problems" do
        before do
          contest.update_attribute(:medal, false)
          contest.organizers << user1
          contest.organizers << user2
          contest.organizers << user3
          contestproblem1.update_attribute(:contest, contest)
          contestproblem2.update_attribute(:contest, contest)
          contestproblem1.update_attribute(:start_time, Time.zone.parse('27-11-2021 11:00:00'))
          contestproblem2.update_attribute(:start_time, Time.zone.parse('29-11-2021 11:00:00'))
        end
        it do
          forum_message = get_new_contest_forum_message(contest)
          expect(forum_message).to include("[url=#{contest_path(contest)}]Concours ##{contest.number}[/url]")
          expect(forum_message).to include("organisé par [b]#{user1.name}[/b], [b]#{user2.name}[/b] et [b]#{user3.name}[/b], vient d'être mis en ligne")
          expect(forum_message).to include("Il comporte [b]2 problèmes[/b] et démarrera le [b]27 novembre 2021[/b]")
          expect(forum_message).to include("Il n'y aura pas de médailles et mentions honorables pour ce concours.")
        end
      end
    end
    
    describe "new correction message" do
      describe "when nobody solved the problem" do
        before do
          contestproblem1.update_attribute(:contest, contest)
          contestproblem1.corrected!
          Contestsolution.create(:contestproblem => contestproblem1, :user => user1, :content => "Ma solution", :score => 3)
        end
        it do
          forum_message = get_new_correction_forum_message(contest, contestproblem1)
          expect(forum_message).to include("Le [url=#{contestproblem_path(contestproblem1)}]Problème ##{contestproblem1.number}[/url] du [url=#{contest_path(contest)}]Concours ##{contest.number}[/url]")
          expect(forum_message).to include("Malheureusement, [b]personne[/b] n'a obtenu la note maximale")
          expect(forum_message).to include("Il s'agissait du dernier problème.")
        end
      end
      
      describe "when one student solved the problem" do
        before do
          contestproblem2.update_attribute(:contest, contest)
          contestproblem2.in_correction! # This problem is not corrected yet so we should not get 'Le classement final...'
          contestproblem1.update_attribute(:contest, contest)
          contestproblem1.corrected!
          Contestsolution.create(:contestproblem => contestproblem1, :user => user1, :content => "Ma solution", :score => 7)
        end
        it do
          forum_message = get_new_correction_forum_message(contest, contestproblem1)
          expect(forum_message).to include("Le [url=#{contestproblem_path(contestproblem1)}]Problème ##{contestproblem1.number}[/url] du [url=#{contest_path(contest)}]Concours ##{contest.number}[/url]")
          expect(forum_message).to include("Seule [b]une seule[/b] personne a obtenu la note maximale : #{user1.name}.")
          expect(forum_message).to include("Le nouveau classement général suite à cette correction")
        end
      end
      
      describe "when three students solved the problem" do
        before do
          contestproblem1.update_attribute(:contest, contest)
          contestproblem1.corrected!
          Contestsolution.create(:contestproblem => contestproblem1, :user => user1, :content => "Ma solution", :score => 7)
          Contestsolution.create(:contestproblem => contestproblem1, :user => user2, :content => "Ma solution", :score => 7)
          Contestsolution.create(:contestproblem => contestproblem1, :user => user3, :content => "Ma solution", :score => 7)
        end
        it do
          forum_message = get_new_correction_forum_message(contest, contestproblem1)
          expect(forum_message).to include("Le [url=#{contestproblem_path(contestproblem1)}]Problème ##{contestproblem1.number}[/url] du [url=#{contest_path(contest)}]Concours ##{contest.number}[/url]")
          expect(forum_message).to include("Les [b]3[/b] personnes suivantes ont obtenu la note maximale : #{user1.name}, #{user2.name} et #{user3.name}.")
        end
      end
    end
    
    describe "problem published in one day message" do
      describe "for one problem" do
        before do
          contestproblem1.update_attribute(:contest, contest)
        end
        it do
          forum_message = get_problems_in_one_day_forum_message(contest, [contestproblem1])
          expect(forum_message).to include("Le Problème ##{contestproblem1.number} du [url=#{contest_path(contest)}]Concours ##{contest.number}[/url] sera publié dans un jour")
        end
      end
      
      describe "for three problems" do
        before do
          contestproblem1.update_attribute(:contest, contest)
          contestproblem2.update_attribute(:contest, contest)
          contestproblem3.update_attribute(:contest, contest)
        end
        it do
          forum_message = get_problems_in_one_day_forum_message(contest, [contestproblem1, contestproblem2, contestproblem3])
          expect(forum_message).to include("Les Problèmes ##{contestproblem1.number}, ##{contestproblem2.number} et ##{contestproblem3.number} du [url=#{contest_path(contest)}]Concours ##{contest.number}[/url] seront publiés dans un jour")
        end
      end
    end
    
    describe "problem published now message" do
      describe "for one problem" do
        before do
          contestproblem1.update_attribute(:contest, contest)
        end
        it do
          forum_message = get_problems_now_forum_message(contest, [contestproblem1])
          expect(forum_message).to include("Le [url=#{contestproblem_path(contestproblem1)}]Problème ##{contestproblem1.number}[/url] du [url=#{contest_path(contest)}]Concours ##{contest.number}[/url] est maintenant accessible, ")
        end
      end
      
      describe "for three problems" do
        before do
          contestproblem1.update_attribute(:contest, contest)
          contestproblem2.update_attribute(:contest, contest)
          contestproblem3.update_attribute(:contest, contest)
        end
        it do
          forum_message = get_problems_now_forum_message(contest, [contestproblem1, contestproblem2, contestproblem3])
          expect(forum_message).to include("Les Problèmes [url=#{contestproblem_path(contestproblem1)}]##{contestproblem1.number}[/url], [url=#{contestproblem_path(contestproblem2)}]##{contestproblem2.number}[/url] et [url=#{contestproblem_path(contestproblem3)}]##{contestproblem3.number}[/url] du [url=#{contest_path(contest)}]Concours ##{contest.number}[/url] sont maintenant accessibles, ")
        end
      end
    end
  end
end
