# -*- coding: utf-8 -*-
require "spec_helper"

describe "layouts/_header.html.erb", type: :view, layout: true do

  subject { rendered }

  let(:user) { FactoryGirl.create(:user, last_forum_visit_time: DateTime.now - 1.day) }
  let(:corrector) { FactoryGirl.create(:corrector) }
  let(:admin) { FactoryGirl.create(:admin) }
  let(:root) { FactoryGirl.create(:root) }
  let!(:section_fondation) { FactoryGirl.create(:section, fondation: true) }
  let!(:section) { FactoryGirl.create(:section) }
  
  context "if the user is not signed in" do
    it "renders the header correctly" do
      render partial: "layouts/header"
      should have_link("Mathraining", href: root_path)
      
      should have_no_link(href: allnew_submissions_path(:levels => 3))
      should have_no_link(href: allnew_submissions_path(:levels => 28))
      should have_no_link(href: allmynew_submissions_path)
      should have_no_link(href: starproposals_path)
      should have_no_link(href: suspicions_path)
      should have_no_link(href: notifs_path)
      
      should have_link("Théorie")
      should have_link(section_fondation.name, href: section_path(section_fondation))
      should have_link(section.name, href: section_path(section))
      should have_no_link("Modifier la structure")
      
      should have_link("Problèmes")
      should have_no_link(section_fondation.name, href: section_problems_path(section_fondation))
      should have_link(section.name, href: section_problems_path(section))
      should have_link("Tests virtuels", href: virtualtests_path)
      should have_link("Concours", href: contests_path)
      
      should have_link("Statistiques")
      
      should have_link("Connexion")
      should have_field("header_connect_email")
      should have_field("header_connect_password")
      should have_button("Connexion")
      should have_link("J'ai oublié mon mot de passe", href: forgot_password_path)
      should have_link("S'inscrire", href: signup_path)
    end
  end
  
  context "if the user is signed in" do
    before { sign_in_view(user) }
    
    it "renders the header correctly" do
      render partial: "layouts/header"
      should have_link("Mathraining", href: root_path)
      
      should have_no_link(href: allnew_submissions_path(:levels => 3))
      should have_no_link(href: allnew_submissions_path(:levels => 28))
      should have_no_link(href: allmynew_submissions_path)
      should have_no_link(href: starproposals_path)
      should have_no_link(href: suspicions_path)
      should have_no_link(href: notifs_path)
      
      should have_link("Théorie")
      should have_link(section_fondation.name, href: section_path(section_fondation))
      should have_link(section.name, href: section_path(section))
      should have_no_link("Modifier la structure")
      
      should have_link("Problèmes")
      should have_no_link(section_fondation.name, href: section_problems_path(section_fondation))
      should have_link(section.name, href: section_problems_path(section))
      should have_link("Tests virtuels", href: virtualtests_path)
      should have_link("Concours", href: contests_path)
      
      should have_link("Statistiques")
      
      should have_no_link("Connexion")
      should have_no_link("S'inscrire", href: signup_path)
      
      should have_link(user.fullname)
      should have_link("Profil", href: user_path(user))
      should have_link("Compte", href: edit_user_path(user))
      should have_no_link("Groupes Wépion", href: groups_users_path)
      should have_link("Messages", href: new_discussion_path)
      should have_no_link("Pièces jointes", href: myfiles_path)
      should have_no_link(href: validate_names_users_path)
      should have_link("Déconnexion", href: sessions_path)
    end
    
    context "and has some notifications" do
      let!(:submission1) { FactoryGirl.create(:submission, user: user, status: :wrong) }
      let!(:submission2) { FactoryGirl.create(:submission, user: user, status: :correct) }
      let!(:submission3) { FactoryGirl.create(:submission, user: user, status: :wrong) }
      
      before do
        submission1.notified_users << user
        submission2.notified_users << user
      end
      
      it "renders the notification button" do
        render partial: "layouts/header"
        should have_link("2", href: notifs_path)
      end
    end
    
    context "and is in Wépion" do
      before { user.update(:wepion => true, :group => "A") }
      
      it "renders the link to Wépion groups" do
        render partial: "layouts/header"
        should have_link("Groupes Wépion", href: groups_users_path)
      end
    end
    
    context "and has a message to read" do
      let!(:discussion) { create_discussion_between(user, admin, "Coucou", "Salut") }
      
      before { discussion.links.where(:user => user).first.update_attribute(:nonread, 1) }
      
      it "renders the number of unread messages correctly" do
        render partial: "layouts/header"
        should have_link(user.fullname + " (1)")
        should have_link("Messages (1)", href: new_discussion_path)
      end
    end
    
    context "and has some forum messages to read" do
      let!(:sub) { FactoryGirl.create(:subject) }
      let!(:message) { FactoryGirl.create(:message, subject: sub) }
      let!(:old_sub) { FactoryGirl.create(:subject) }
      let!(:old_message) { FactoryGirl.create(:message, subject: old_sub, created_at: DateTime.now - 3.days) }
      
      before { user.update_attribute(:last_forum_visit_time, DateTime.now - 1.day) }
      
      it "renders the number of unread forum messages correctly" do
        render partial: "layouts/header"
        should have_link("Forum (1)", href: subjects_path)
      end
    end
    
    context "and is a corrector" do
      before { user.update_attribute(:corrector, true) }
      
      it "renders the buttons for correctors" do
        render partial: "layouts/header"
        should have_link(href: allnew_submissions_path(:levels => 3))
        should have_link(href: allnew_submissions_path(:levels => 28))
        should have_link("0", href: allmynew_submissions_path)
      end
      
      context "and has new comments to read" do
        let!(:following) { FactoryGirl.create(:following, user: user, read: false) }
        
        it "renders the number of comments to read correctly" do
          render partial: "layouts/header"
          should have_link("1", href: allmynew_submissions_path)
        end
      end
    end
  end
  
  context "if the user is an admin" do
    before { sign_in_view(admin) }
    
    it "renders the header correctly" do
      render partial: "layouts/header"
      should have_link("Mathraining", href: root_path)
      
      should have_link(href: allnew_submissions_path(:levels => 3))
      should have_link(href: allnew_submissions_path(:levels => 28))
      should have_link("0", href: allmynew_submissions_path)
      should have_no_link(href: starproposals_path)
      should have_no_link(href: suspicions_path)
      should have_no_link(href: notifs_path)
      
      should have_link("Théorie")
      should have_link(section_fondation.name, href: section_path(section_fondation))
      should have_link(section.name, href: section_path(section))
      should have_link("Modifier la structure")
      
      should have_link("Problèmes")
      should have_no_link(section_fondation.name, href: section_problems_path(section_fondation))
      should have_link(section.name, href: section_problems_path(section))
      should have_link("Tests virtuels", href: virtualtests_path)
      should have_link("Concours", href: contests_path)
      
      should have_link("Statistiques")
      
      should have_no_link("Connexion")
      should have_no_link("S'inscrire", href: signup_path)
      
      should have_link(admin.fullname)
      should have_link("Profil", href: user_path(admin))
      should have_link("Compte", href: edit_user_path(admin))
      should have_link("Groupes Wépion", href: groups_users_path)
      should have_link("Messages", href: new_discussion_path)
      should have_no_link("Pièces jointes", href: myfiles_path)
      should have_no_link(href: validate_names_users_path)
      should have_link("Déconnexion", href: sessions_path)
    end
  end
  
  context "if the user is a root" do
    before { sign_in_view(root) }
    
    it "renders the header correctly" do
      render partial: "layouts/header"
      should have_link("Mathraining", href: root_path)
      
      should have_link(href: allnew_submissions_path(:levels => 3))
      should have_link(href: allnew_submissions_path(:levels => 28))
      should have_link("0", href: allmynew_submissions_path)
      should have_no_link(href: starproposals_path)
      should have_no_link(href: suspicions_path)
      should have_no_link(href: notifs_path)
      
      should have_link("Théorie")
      should have_link(section_fondation.name, href: section_path(section_fondation))
      should have_link(section.name, href: section_path(section))
      should have_link("Modifier la structure")
      
      should have_link("Problèmes")
      should have_no_link(section_fondation.name, href: section_problems_path(section_fondation))
      should have_link(section.name, href: section_problems_path(section))
      should have_link("Tests virtuels", href: virtualtests_path)
      should have_link("Concours", href: contests_path)
      
      should have_link("Statistiques")
      
      should have_no_link("Connexion")
      should have_no_link("S'inscrire", href: signup_path)
      
      should have_link(root.fullname)
      should have_link("Profil", href: user_path(root))
      should have_link("Compte", href: edit_user_path(root))
      should have_link("Groupes Wépion", href: groups_users_path)
      should have_link("Messages", href: new_discussion_path)
      should have_link("Pièces jointes", href: myfiles_path)
      should have_link("Valider 0 noms", href: validate_names_users_path)
      should have_link("Déconnexion", href: sessions_path)
    end
    
    context "and there is a suspicion" do
      let!(:suspicion) { FactoryGirl.create(:suspicion) }
      
      it "renders the suspicion button" do
        render partial: "layouts/header"
        should have_link("1", href: suspicions_path)
      end
    end
    
    context "and there is a star proposal" do
      let!(:starproposal) { FactoryGirl.create(:starproposal) }
      
      it "renders the star proposal button" do
        render partial: "layouts/header"
        should have_link("1", href: starproposals_path)
      end
    end
    
    context "and there is a name to validate" do
      let!(:new_user) { FactoryGirl.create(:user, valid_name: false) }
      
      it "renders the number of user names to validate" do
        render partial: "layouts/header"
        should have_link("Valider 1 noms", href: validate_names_users_path)
      end
    end
  end
end
