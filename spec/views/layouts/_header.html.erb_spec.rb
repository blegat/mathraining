# -*- coding: utf-8 -*-
require "spec_helper"

describe "layouts/_header.html.erb", type: :view, layout: true do

  let(:user) { FactoryGirl.create(:user, last_forum_visit_time: DateTime.now - 1.day) }
  let(:corrector) { FactoryGirl.create(:corrector) }
  let(:admin) { FactoryGirl.create(:admin) }
  let(:root) { FactoryGirl.create(:root) }
  let!(:section_fondation) { FactoryGirl.create(:section, fondation: true) }
  let!(:section) { FactoryGirl.create(:section) }
  
  context "if the user is not signed in" do
    it "renders the header correctly" do
      render partial: "layouts/header"
      expect(rendered).to have_link("Mathraining", href: root_path)
      
      expect(rendered).to have_no_link(href: allnewsub_path(:levels => 3))
      expect(rendered).to have_no_link(href: allnewsub_path(:levels => 28))
      expect(rendered).to have_no_link(href: allmynewsub_path)
      expect(rendered).to have_no_link(href: starproposals_path)
      expect(rendered).to have_no_link(href: suspicions_path)
      expect(rendered).to have_no_link(href: notifs_path)
      
      expect(rendered).to have_link("Théorie")
      expect(rendered).to have_link(section_fondation.name, href: section_path(section_fondation))
      expect(rendered).to have_link(section.name, href: section_path(section))
      expect(rendered).to have_no_link("Modifier la structure")
      
      expect(rendered).to have_link("Problèmes")
      expect(rendered).to have_no_link(section_fondation.name, href: pb_sections_path(section_fondation))
      expect(rendered).to have_link(section.name, href: pb_sections_path(section))
      expect(rendered).to have_link("Tests virtuels", href: virtualtests_path)
      expect(rendered).to have_link("Concours", href: contests_path)
      
      expect(rendered).to have_link("Statistiques")
      
      expect(rendered).to have_link("Connexion")
      expect(rendered).to have_field("header_connect_email")
      expect(rendered).to have_field("header_connect_password")
      expect(rendered).to have_button("Connexion")
      expect(rendered).to have_link("J'ai oublié mon mot de passe", href: forgot_password_path)
      expect(rendered).to have_link("S'inscrire", href: signup_path)
    end
  end
  
  context "if the user is signed in" do
    before do
      assign(:current_user, user)
    end
    
    it "renders the header correctly" do
      render partial: "layouts/header"
      expect(rendered).to have_link("Mathraining", href: root_path)
      
      expect(rendered).to have_no_link(href: allnewsub_path(:levels => 3))
      expect(rendered).to have_no_link(href: allnewsub_path(:levels => 28))
      expect(rendered).to have_no_link(href: allmynewsub_path)
      expect(rendered).to have_no_link(href: starproposals_path)
      expect(rendered).to have_no_link(href: suspicions_path)
      expect(rendered).to have_no_link(href: notifs_path)
      
      expect(rendered).to have_link("Théorie")
      expect(rendered).to have_link(section_fondation.name, href: section_path(section_fondation))
      expect(rendered).to have_link(section.name, href: section_path(section))
      expect(rendered).to have_no_link("Modifier la structure")
      
      expect(rendered).to have_link("Problèmes")
      expect(rendered).to have_no_link(section_fondation.name, href: pb_sections_path(section_fondation))
      expect(rendered).to have_link(section.name, href: pb_sections_path(section))
      expect(rendered).to have_link("Tests virtuels", href: virtualtests_path)
      expect(rendered).to have_link("Concours", href: contests_path)
      
      expect(rendered).to have_link("Statistiques")
      
      expect(rendered).to have_no_link("Connexion")
      expect(rendered).to have_no_link("S'inscrire", href: signup_path)
      
      expect(rendered).to have_link(user.fullname)
      expect(rendered).to have_link("Profil", href: user_path(user))
      expect(rendered).to have_link("Compte", href: edit_user_path(user))
      expect(rendered).to have_no_link("Groupes Wépion", href: groups_path)
      expect(rendered).to have_link("Messages", href: new_discussion_path)
      expect(rendered).to have_no_link("Pièces jointes", href: myfiles_path)
      expect(rendered).to have_no_link(href: validate_names_path)
      expect(rendered).to have_link("Déconnexion", href: signout_path)
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
        expect(rendered).to have_link("2", href: notifs_path)
      end
    end
    
    context "and is in Wépion" do
      before do
        user.update(:wepion => true, :group => "A")
      end
      
      it "renders the link to Wépion groups" do
        render partial: "layouts/header"
        expect(rendered).to have_link("Groupes Wépion", href: groups_path)
      end
    end
    
    context "and has a message to read" do
      let!(:discussion) { create_discussion_between(user, admin, "Coucou", "Salut") }
      before do
        discussion.links.where(:user => user).first.update_attribute(:nonread, 1)
      end
      
      it "renders the number of unread messages correctly" do
        render partial: "layouts/header"
        expect(rendered).to have_link(user.fullname + " (1)")
        expect(rendered).to have_link("Messages (1)", href: new_discussion_path)
      end
    end
    
    context "and has some forum messages to read" do
      let!(:subject) { FactoryGirl.create(:subject) }
      let!(:message) { FactoryGirl.create(:message, subject: subject) }
      let!(:old_subject) { FactoryGirl.create(:subject) }
      let!(:old_message) { FactoryGirl.create(:message, subject: old_subject, created_at: DateTime.now - 3.days) }
      before do
        user.update_attribute(:last_forum_visit_time, DateTime.now - 1.day)
      end
      
      it "renders the number of unread forum messages correctly" do
        render partial: "layouts/header"
        expect(rendered).to have_link("Forum (1)", href: subjects_path)
      end
    end
    
    context "and is a corrector" do
      before do
        user.update_attribute(:corrector, true)
      end
      
      it "renders the buttons for correctors" do
        render partial: "layouts/header"
        expect(rendered).to have_link(href: allnewsub_path(:levels => 3))
        expect(rendered).to have_link(href: allnewsub_path(:levels => 28))
        expect(rendered).to have_link("0", href: allmynewsub_path)
      end
      
      context "and has new comments to read" do
        let!(:following) { FactoryGirl.create(:following, user: user, read: false) }
        
        it "renders the number of comments to read correctly" do
          render partial: "layouts/header"
          expect(rendered).to have_link("1", href: allmynewsub_path)
        end
      end
    end
  end
  
  context "if the user is an admin" do
    before do
      assign(:current_user, admin)
    end
    
    it "renders the header correctly" do
      render partial: "layouts/header"
      expect(rendered).to have_link("Mathraining", href: root_path)
      
      expect(rendered).to have_link(href: allnewsub_path(:levels => 3))
      expect(rendered).to have_link(href: allnewsub_path(:levels => 28))
      expect(rendered).to have_link("0", href: allmynewsub_path)
      expect(rendered).to have_no_link(href: starproposals_path)
      expect(rendered).to have_no_link(href: suspicions_path)
      expect(rendered).to have_no_link(href: notifs_path)
      
      expect(rendered).to have_link("Théorie")
      expect(rendered).to have_link(section_fondation.name, href: section_path(section_fondation))
      expect(rendered).to have_link(section.name, href: section_path(section))
      expect(rendered).to have_link("Modifier la structure")
      
      expect(rendered).to have_link("Problèmes")
      expect(rendered).to have_no_link(section_fondation.name, href: pb_sections_path(section_fondation))
      expect(rendered).to have_link(section.name, href: pb_sections_path(section))
      expect(rendered).to have_link("Tests virtuels", href: virtualtests_path)
      expect(rendered).to have_link("Concours", href: contests_path)
      
      expect(rendered).to have_link("Statistiques")
      
      expect(rendered).to have_no_link("Connexion")
      expect(rendered).to have_no_link("S'inscrire", href: signup_path)
      
      expect(rendered).to have_link(admin.fullname)
      expect(rendered).to have_link("Profil", href: user_path(admin))
      expect(rendered).to have_link("Compte", href: edit_user_path(admin))
      expect(rendered).to have_link("Groupes Wépion", href: groups_path)
      expect(rendered).to have_link("Messages", href: new_discussion_path)
      expect(rendered).to have_no_link("Pièces jointes", href: myfiles_path)
      expect(rendered).to have_no_link(href: validate_names_path)
      expect(rendered).to have_link("Déconnexion", href: signout_path)
    end
  end
  
  context "if the user is a root" do
    before do
      assign(:current_user, root)
    end
    
    it "renders the header correctly" do
      render partial: "layouts/header"
      expect(rendered).to have_link("Mathraining", href: root_path)
      
      expect(rendered).to have_link(href: allnewsub_path(:levels => 3))
      expect(rendered).to have_link(href: allnewsub_path(:levels => 28))
      expect(rendered).to have_link("0", href: allmynewsub_path)
      expect(rendered).to have_no_link(href: starproposals_path)
      expect(rendered).to have_no_link(href: suspicions_path)
      expect(rendered).to have_no_link(href: notifs_path)
      
      expect(rendered).to have_link("Théorie")
      expect(rendered).to have_link(section_fondation.name, href: section_path(section_fondation))
      expect(rendered).to have_link(section.name, href: section_path(section))
      expect(rendered).to have_link("Modifier la structure")
      
      expect(rendered).to have_link("Problèmes")
      expect(rendered).to have_no_link(section_fondation.name, href: pb_sections_path(section_fondation))
      expect(rendered).to have_link(section.name, href: pb_sections_path(section))
      expect(rendered).to have_link("Tests virtuels", href: virtualtests_path)
      expect(rendered).to have_link("Concours", href: contests_path)
      
      expect(rendered).to have_link("Statistiques")
      
      expect(rendered).to have_no_link("Connexion")
      expect(rendered).to have_no_link("S'inscrire", href: signup_path)
      
      expect(rendered).to have_link(root.fullname)
      expect(rendered).to have_link("Profil", href: user_path(root))
      expect(rendered).to have_link("Compte", href: edit_user_path(root))
      expect(rendered).to have_link("Groupes Wépion", href: groups_path)
      expect(rendered).to have_link("Messages", href: new_discussion_path)
      expect(rendered).to have_link("Pièces jointes", href: myfiles_path)
      expect(rendered).to have_link("Valider 0 noms", href: validate_names_path)
      expect(rendered).to have_link("Déconnexion", href: signout_path)
    end
    
    context "and there is a suspicion" do
      let!(:suspicion) { FactoryGirl.create(:suspicion) }
      
      it "renders the suspicion button" do
        render partial: "layouts/header"
        expect(rendered).to have_link("1", href: suspicions_path)
      end
    end
    
    context "and there is a star proposal" do
      let!(:starproposal) { FactoryGirl.create(:starproposal) }
      
      it "renders the star proposal button" do
        render partial: "layouts/header"
        expect(rendered).to have_link("1", href: starproposals_path)
      end
    end
    
    context "and there is a name to validate" do
      let!(:new_user) { FactoryGirl.create(:user, valid_name: false) }
      
      it "renders the number of user names to validate" do
        render partial: "layouts/header"
        expect(rendered).to have_link("Valider 1 noms", href: validate_names_path)
      end
    end
  end
end
