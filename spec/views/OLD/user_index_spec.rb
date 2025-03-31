# -*- coding: utf-8 -*-
require "spec_helper"

describe "Page user/index" do

  subject { page }
  
  let!(:country1) { FactoryGirl.create(:country) }
  let!(:country2) { FactoryGirl.create(:country) }
  let!(:country3) { FactoryGirl.create(:country) }
  
  let!(:section) { FactoryGirl.create(:section, fondation: false) }
  let!(:section_fondation) { FactoryGirl.create(:section, fondation: true) }
  let!(:chapter)  { FactoryGirl.create(:chapter, section: section, online: true) }
  let!(:chapter_fondation) { FactoryGirl.create(:chapter, section: section_fondation, online: true) }
  let!(:problem1) { FactoryGirl.create(:problem, section: section, level: 1, online: true) }
  let!(:problem2) { FactoryGirl.create(:problem, section: section, level: 2, online: true) }
  let!(:question1) { FactoryGirl.create(:exercise, chapter: chapter, level: 1, online: true) }
  let!(:question2) { FactoryGirl.create(:exercise_decimal, chapter: chapter, level: 2, online: true) }
  let!(:question3) { FactoryGirl.create(:exercise, chapter: chapter_fondation, level: 3, online: true) }

  let!(:root)   { FactoryGirl.create(:root, country: country1) }
  let!(:admin1) { FactoryGirl.create(:admin, country: country1) }
  let!(:admin2) { FactoryGirl.create(:admin, country: country2) }
  let!(:user1)  { FactoryGirl.create(:user, country: country1, rating: 6000*3/2) } # Maître
  let!(:user2)  { FactoryGirl.create(:user, country: country2, rating: 6000*3/2) } # Maître
  let!(:user3)  { FactoryGirl.create(:user, country: country1, rating: 4000*3/2) } # Expert
  let!(:user4)  { FactoryGirl.create(:user, country: country1, rating: 3000*3/2) } # Chevronné
  let!(:user5)  { FactoryGirl.create(:user, country: country2, rating: 2000*3/2) } # Chevronné
  let!(:user6)  { FactoryGirl.create(:user, country: country2, rating: 1000*3/2) } # Qualifié
  let!(:user7)  { FactoryGirl.create(:user, country: country2, rating: 500*3/2) }  # Compétent
  let!(:user8)  { FactoryGirl.create(:user, country: country1, rating: 500*3/2) }  # Compétent
  let!(:user9)  { FactoryGirl.create(:user, country: country1, rating: 500*3/2) }  # Compétent
  let!(:user10) { FactoryGirl.create(:user, country: country2, rating: 300*3/2) }  # Initié
  let!(:user11) { FactoryGirl.create(:user, country: country1, rating: 200*3/2) }  # Initié
  let!(:user12) { FactoryGirl.create(:user, country: country1, rating: 100*3/2) }  # Débutant
  let!(:user13) { FactoryGirl.create(:user, country: country1, rating: 50*3/2) }   # Novice
  let!(:user14) { FactoryGirl.create(:user, country: country2, rating: 10*3/2) }   # Novice
  let!(:user15) { FactoryGirl.create(:user, country: country1, rating: 0) }
  let!(:user16) { FactoryGirl.create(:user, country: country2, rating: 0) }
  let!(:user17) { FactoryGirl.create(:user, country: country2, rating: 0, email_confirm: false) }
  
  before(:all) do
    Color.create_defaults
  end
  
  after(:all) do
    Color.delete_all
  end
  
  before(:each) do
    r = Random.new(Date.today.in_time_zone.to_time.to_i)
    
    # Initialize Pointspersection randomly
    Section.where(:fondation => false).each do |s|
      s.update_attribute(:max_score, (r.rand() * 1000).to_i)
      User.where(:role => :student).each do |u|
        pps = Pointspersection.where(:user => u, :section => s).first
        pps.update_attribute(:points, [[(r.rand() * (s.max_score+100)).to_i - 50, 0].max, s.max_score].min)
      end
    end
    
    # Initialize recently solved problems and questions randomly
    User.where(:role => :student).each do |u|
      Problem.all.each do |p|
        if r.rand() < 0.5 # Tried to solve the problem
          if r.rand() < 0.5 # Incorrect
            FactoryGirl.create(:submission, problem: p, user: u, status: :wrong)
          else # Correct
            sub = FactoryGirl.create(:submission, problem: p, user: u, status: :correct)
            time = DateTime.now - ((rand() * 28).to_i).days # Date of resolution in the last 4 weeks
            FactoryGirl.create(:solvedproblem, problem: p, user: u, submission: sub, resolution_time: time)
          end
        end
      end
      
      Question.all.each do |q|
        if r.rand() < 0.5 # Tried to solved the exercise
          correct = r.rand() < 0.5 # Correct solution or not
          time = DateTime.now - ((rand() * 28).to_i).days # Date of resolution in the last 4 weeks
          if correct
            FactoryGirl.create(:solvedquestion, question: q, user: u, resolution_time: time)
          else
            FactoryGirl.create(:unsolvedquestion, question: q, user: u, last_guess_time: time)
          end
        end
      end
    end
  end
  
  describe "visitor" do
    describe "all titles and all countries (page 1)" do
      before { visit users_path }
      it do
        should have_selector("h1", text: "Scores")
        
        should have_select("title", :options => options_for_user_titles(0, false))
        should have_select("country", :options => ["Tous les pays (14)", "#{country1.name} (8)", "#{country2.name} (6)"])
        
        should { (have_user_line(1, "2.", user1) and have_user_line(2, "", user2)) or
                 (have_user_line(1, "2.", user2) and have_user_line(2, "", user1)) }    
        should have_user_line(3,  "4.",  user3)
        should have_user_line(4,  "5.",  user4)
        should have_user_line(5,  "6.",  user5)
        should have_user_line(6,  "7.",  user6)
        should have_user_line(7,  "8.",  user7)
        should have_user_line(8,  "",    user8)
        should have_user_line(9,  "",    user9)
        should have_user_line(10, "11.", user10)
        should have_no_selector("#rank_11")
      end
    end
    
    describe "all titles and all countries (page 2)" do
      before { visit users_path(:page => 2) }
      it do
        should have_selector("h1", text: "Scores")
        
        should have_select("title", :options => options_for_user_titles(0, false))
        should have_select("country", :options => ["Tous les pays (14)", "#{country1.name} (8)", "#{country2.name} (6)"])
        
        should have_user_line(1, "12.", user11)
        should have_user_line(2, "13.", user12)
        should have_user_line(3, "14.", user13)
        should have_user_line(4, "15.", user14)
        should have_no_selector("#rank_5")
      end
    end
    
    describe "one title and all countries" do
      before { visit users_path(:title => Color.where(:name => "Chevronné").first) }
      it do
        should have_selector("h1", text: "Scores")
        
        should have_select("title", :options => options_for_user_titles(0, false))
        should have_select("country", :options => ["Tous les pays (2)", "#{country1.name} (1)", "#{country2.name} (1)"])
        
        should have_user_line(1,  "5.",  user4)
        should have_user_line(2,  "6.",  user5)
        should have_no_selector("#rank_3")
      end
    end
    
    describe "one title without anybody and all countries" do
      before { visit users_path(:title => Color.where(:name => "Expérimenté").first) }
      it do
        should have_selector("h1", text: "Scores")
        
        should have_select("title", :options => options_for_user_titles(0, false))
        should have_select("country", :options => ["Tous les pays (0)"])
        
        should have_content("Aucun utilisateur.")
        should have_no_selector("#rank_1")
      end
    end
    
    describe "one country and all titles" do
      before { visit users_path(:country => country1.id) }
      it do
        should have_selector("h1", text: "Scores")
        
        should have_select("title", :options => options_for_user_titles(country1.id, false))
        should have_select("country", :options => ["Tous les pays (14)", "#{country1.name} (8)", "#{country2.name} (6)"])
        
        should have_user_line(1, "2.",  user1)
        should have_user_line(2, "4.",  user3)
        should have_user_line(3, "5.",  user4)
        should have_user_line(4, "8.",  user8)
        should have_user_line(5, "",    user9)
        should have_user_line(6, "12.", user11)
        should have_user_line(7, "13.", user12)
        should have_user_line(8, "14.", user13)
        should have_no_selector("#rank_9")
      end
    end
    
    describe "one country without anybody and all titles" do
      before { visit users_path(:country => country3) }
      it do
        should have_selector("h1", text: "Scores")
        
        should have_select("title", :options => options_for_user_titles(country3.id, false))
        should have_select("country", :options => ["Tous les pays (14)", "#{country1.name} (8)", "#{country2.name} (6)", "#{country3.name} (0)"])
        
        should have_content("Aucun utilisateur.")
        should have_no_selector("#rank_1")
      end
    end
    
    describe "one title and one country" do
      before { visit users_path(:title => Color.where(:name => "Compétent").first, :country => country1) }
      it do
        should have_selector("h1", text: "Scores")
        
        should have_select("title", :options => options_for_user_titles(country1.id, false))
        should have_select("country", :options => ["Tous les pays (3)", "#{country1.name} (2)", "#{country2.name} (1)"])
        
        should have_user_line(1, "8.", user8)
        should have_user_line(2, "",   user9)
        should have_no_selector("#rank_3")
      end
    end
    
    describe "one title and one country, with nobody" do
      before { visit users_path(:title => Color.where(:name => "Débutant").first, :country => country2) }
      it do
        should have_selector("h1", text: "Scores")
        
        should have_select("title", :options => options_for_user_titles(country2.id, false))
        should have_select("country", :options => ["Tous les pays (1)", "#{country1.name} (1)", "#{country2.name} (0)"])
        
        should have_content("Aucun utilisateur.")
        should have_no_selector("#rank_1")
      end
    end
  end
  
  describe "user ranked first" do
    before { sign_in user2 }
    
    describe "all titles and all countries (page 1), with 3 users ranked firsts" do
      before do
        user3.update_attribute(:rating, 6000)
        visit users_path
      end
      it do
        should have_selector("h1", text: "Scores")
        
        should have_link("Tous les utilisateurs", href: users_path)
        should have_link("Utilisateurs suivis", href: followed_users_path)
        
        should have_select("title", :options => options_for_user_titles(0, false))
        should have_select("country", :options => ["Tous les pays (14)", "#{country1.name} (8)", "#{country2.name} (6)"])
        
        #should have_user_line(1, "2.",   user2) # The current user should always appear first 
        #should { (have_user_line(2, "", user1) and have_user_line(3,  "",  user3)) or
        #         (have_user_line(2, "", user3) and have_user_line(3,  "",  user1)) }
        should have_user_line(4,  "5.",  user4)
        should have_user_line(5,  "6.",  user5)
        should have_user_line(6,  "7.",  user6)
        should have_user_line(7,  "8.",  user7)
        should have_user_line(8,  "",    user8)
        should have_user_line(9,  "",    user9)
        should have_user_line(10, "11.", user10)
        should have_no_selector("#rank_11")
      end
    end
    
    describe "one title and all countries" do
      before { visit users_path(:title => Color.where(:name => "Maître").first) }
      it do
        should have_selector("h1", text: "Scores")
        
        should have_link("Tous les utilisateurs", href: users_path)
        should have_link("Utilisateurs suivis", href: followed_users_path)
        
        should have_select("title", :options => options_for_user_titles(0, false))
        should have_select("country", :options => ["Tous les pays (2)", "#{country1.name} (1)", "#{country2.name} (1)"])
        
        #should have_user_line(1, "2.", user2) # The current user should always appear first
        #should have_user_line(2, "", user1)
        should have_no_selector("#rank_3")
      end
    end
    
    describe "followed users when nobody is followed" do
      before { visit followed_users_path }
      it do
        should have_selector("h1", text: "Scores")
      
        should have_link("Tous les utilisateurs", href: users_path)
        should have_link("Utilisateurs suivis", href: followed_users_path)
        
        should have_content("Vous pouvez suivre d'autres utilisateurs en vous rendant sur leur profil.")
        
        should have_user_line(1, "2.", user2)
        should have_no_selector("#rank_2")
      end
    end
    
    describe "followed users when several users are followed" do
      before do
        user2.followed_users << user17
        user2.followed_users << user1
        user2.followed_users << user9
        user2.followed_users << user16
        visit followed_users_path
      end
      it do
        should have_selector("h1", text: "Scores")
      
        should have_link("Tous les utilisateurs", href: users_path)
        should have_link("Utilisateurs suivis", href: followed_users_path)
        
        should have_content("Vous pouvez suivre d'autres utilisateurs en vous rendant sur leur profil.")
        
        #should have_user_line(1, "2.",  user2) # The current user should always appear first
        #should have_user_line(2, "",    user1)
        should have_user_line(3, "8.",  user9)
        should have_user_line(4, "16.", user16)
        should have_user_line(5, "",    user17)
        should have_no_selector("#rank_6")
      end
    end
  end
  
  describe "root" do
    before { sign_in root }
    
    describe "all titles and all countries (page 1), by choosing wrong title" do
      before { visit users_path(:title => 90) }
      it do
        should have_selector("h1", text: "Scores")
        
        should have_select("title", :options => options_for_user_titles(0, true))
        should have_select("country", :options => ["Tous les pays (14)", "#{country1.name} (8)", "#{country2.name} (6)"])
        
        should { (have_user_line(1, "2.", user1) and have_user_line(2, "", user2)) or
                 (have_user_line(1, "2.", user2) and have_user_line(2, "", user1)) }    
        should have_user_line(3,  "4.",  user3)
        should have_user_line(4,  "5.",  user4)
        should have_user_line(5,  "6.",  user5)
        should have_user_line(6,  "7.",  user6)
        should have_user_line(7,  "8.",  user7)
        should have_user_line(8,  "",    user8)
        should have_user_line(9,  "",    user9)
        should have_user_line(10, "11.", user10)
        should have_no_selector("#rank_11")
      end
    end
    
    describe "unranked users and all countries" do
      before { visit users_path(:title => -1) }
      it do
        should have_selector("h1", text: "Scores")
        
        should have_select("title", :options => options_for_user_titles(0, true))
        should have_select("country", :options => ["Tous les pays (3)", "#{country2.name} (2)", "#{country1.name} (1)"])
        
        should have_no_link(user14.name, href: user_path(user14)) # Because rank > 0
        should have_link(user15.name, href: user_path(user15))
        should have_link(user16.name, href: user_path(user16))
        should have_link(user17.name, href: user_path(user17))
      end
    end
    
    describe "unranked users and one country" do
      before { visit users_path(:title => -1, :country => country2) }
      it do
        should have_selector("h1", text: "Scores")
        
        should have_select("title", :options => options_for_user_titles(country2.id, true))
        should have_select("country", :options => ["Tous les pays (3)", "#{country2.name} (2)", "#{country1.name} (1)"])
        
        should have_no_link(user14.name, href: user_path(user14)) # Because rank > 0
        should have_no_link(user15.name, href: user_path(user15)) # Because not from country2
        should have_link(user16.name, href: user_path(user16))
        should have_link(user17.name, href: user_path(user17))
      end
    end
    
    describe "admin users and all countries" do
      before { visit users_path(:title => -2) }
      it do
        should have_selector("h1", text: "Scores")
        
        should have_select("title", :options => options_for_user_titles(0, true))
        should have_select("country", :options => ["Tous les pays (3)", "#{country1.name} (2)", "#{country2.name} (1)"])
        
        should have_link(root.name, href: user_path(root))
        should have_link(admin1.name, href: user_path(admin1))
        should have_link(admin2.name, href: user_path(admin2))
      end
    end
    
    describe "admin users and one country" do
      before { visit users_path(:title => -2, :country => country2) }
      it do
        should have_selector("h1", text: "Scores")
        
        should have_select("title", :options => options_for_user_titles(country2.id, true))
        should have_select("country", :options => ["Tous les pays (3)", "#{country1.name} (2)", "#{country2.name} (1)"])
        
        should have_no_link(root.name, href: user_path(root))
        should have_no_link(admin1.name, href: user_path(admin1))
        should have_link(admin2.name, href: user_path(admin2))
      end
    end
    
    describe "followed users when nobody is followed" do
      before { visit followed_users_path }
      it do
        should have_selector("h1", text: "Scores")
      
        should have_link("Tous les utilisateurs", href: users_path)
        should have_link("Utilisateurs suivis", href: followed_users_path)
        
        should have_content("Vous pouvez suivre d'autres utilisateurs en vous rendant sur leur profil.")
        
        should have_content("Aucun utilisateur suivi.")
        should have_no_selector("#rank_1")
      end
    end
    
    describe "followed users when several users are followed" do
      before do
        root.followed_users << user3
        root.followed_users << user8
        root.followed_users << user7
        root.followed_users << user15
        visit followed_users_path
      end
      it do
        should have_selector("h1", text: "Scores")
      
        should have_link("Tous les utilisateurs", href: users_path)
        should have_link("Utilisateurs suivis", href: followed_users_path)
        
        should have_content("Vous pouvez suivre d'autres utilisateurs en vous rendant sur leur profil.")
        
        should have_user_line(1, "4.",  user3)
        should have_user_line(2, "8.",  user7)
        should have_user_line(3, "",    user8)
        should have_user_line(4, "16.", user15)
        should have_no_selector("#rank_5")
      end
    end
  end
end
