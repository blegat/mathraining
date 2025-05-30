# -*- coding: utf-8 -*-
require "spec_helper"

feature 'Emailer' do
  describe "inscription emails" do
    let!(:country) { FactoryBot.create(:country) }
    
    before do
      clear_emails
      visit signup_path(:hide_code_of_conduct => 1)
      fill_in "Prénom", with: "Jean"
      fill_in "Nom", with: "Biboux"
      select country.name, from: "Pays"
      select "1977", from: "Année de naissance"
      # Il y a deux fois ces champs (pour la connexion et l"inscription)
      page.all(:fillable_field, "Adresse e-mail").last.set("jean@biboux.com")
      fill_in "Confirmation de l'adresse e-mail", with: "jean@biboux.com"
      page.all(:fillable_field, "Mot de passe").last.set("MotDePasse123")
      fill_in "Confirmation du mot de passe", with: "MotDePasse123"
      check "consent1"
      check "consent2"
      click_button "Créer mon compte"
    end
    
    specify do
      expect(page).to have_success_message("Vous allez recevoir un e-mail de confirmation d'ici quelques minutes pour activer votre compte.")
      open_email("jean@biboux.com")
      expect(current_email.subject).to eq("Mathraining - Confirmation d'inscription")
      expect(current_email).to have_content("Bonjour Jean")
      expect(current_email).to have_content("Bienvenue sur Mathraining !")
      expect(current_email).to have_link("https://www.mathraining.be/activate?id=#{ User.last.id }&key=#{ User.last.key }")
    end
  end
  
  describe "forgot password emails" do
    let!(:user) { FactoryBot.create(:user) }
    before do
      clear_emails
      visit forgot_password_path
      fill_in "user_email", with: user.email
      click_button "Envoyer l'e-mail"
      
    end
     
    specify do
      expect(page).to have_success_message("Vous allez recevoir un e-mail d'ici quelques minutes")
      open_email(user.email)
      expect(current_email.subject).to eq("Mathraining - Mot de passe oublié")
      expect(current_email).to have_content("Il semblerait que vous ayez oublié votre mot de passe.")
      expect(current_email).to have_link("https://www.mathraining.be/users/#{ user.id }/recup_password?key=#{ user.key }")
    end
  end

  describe "tchatmessage emails" do
    let(:user) { FactoryBot.create(:user) }
    let!(:other_user) { FactoryBot.create(:user, last_connexion_date: DateTime.now) } # last_connexion_date to be sure that other_user appears in the list
  
    before do
      clear_emails
      other_user.update_attribute(:follow_message, true)
      sign_in user
      visit new_discussion_path
      select other_user.name, from: "qui"
      fill_in "MathInput", with: "Salut !"
      click_button "Envoyer"
    end
  
    specify do
      open_email(other_user.email)
      expect(current_email.subject).to eq("Mathraining - Nouveau message de #{user.name}")
      expect(current_email).to have_content "#{user.name} vous a envoyé un message sur Mathraining"
      expect(current_email).to have_link("ici", href: discussion_url(Discussion.order(:id).last, :host => "www.mathraining.be"))
      expect(current_email).to have_link("ici", href: unset_follow_message_url(:host => "www.mathraining.be"))
    end
  end
  
  describe "message emails" do
    let(:user) { FactoryBot.create(:user) }
    let!(:other_user) { FactoryBot.create(:user) }
    let!(:sub) { FactoryBot.create(:subject) }
    
    before do
      clear_emails
      other_user.followed_subjects << sub
      sign_in user
      visit subject_path(sub)
      fill_in "MathInputNewMessage", with: "Voici un nouveau message"
      click_button "Poster"
    end
    
    specify do
      open_email(other_user.email)
      expect(page).to have_success_message("Votre message a bien été posté.")
      expect(current_email.subject).to eq("Mathraining - Nouveau message sur le sujet '#{ sub.title }'")
      expect(current_email).to have_content("#{user.name} a posté un message sur le sujet '#{ sub.title }' que vous suivez")
      expect(current_email).to have_link("ici", href: subject_url(sub, :host => "www.mathraining.be", :page => 1, :anchor => "bottom"))
      expect(current_email).to have_link("ici", href: unfollow_subject_url(sub, :host => "www.mathraining.be"))
    end
  end
  
  describe "group message emails" do
    let!(:user_in_group_A) { FactoryBot.create(:user, wepion: true, group: "A") }
    let(:root) { FactoryBot.create(:root) }
    
    describe "new subject" do
      before do
        clear_emails
        sign_in root
        visit new_subject_path
        fill_in "Titre", with: "Sujet pour Wépion"
        fill_in "MathInput", with: "Message important pour Wépion"
        check "subject[for_wepion]"
        check "emailWepion"
        click_button "Créer"
      end
      
      specify do
        open_email(user_in_group_A.email)
        expect(current_email.subject).to eq("Mathraining - Message à l'attention des élèves de Wépion")
        expect(current_email).to have_content("#{root.name} a posté un nouveau message sur Mathraining")
        expect(current_email).to have_link("ici", href: subject_url(Subject.order(:id).last, :host => "www.mathraining.be", :page => 1, :anchor => "bottom"))
      end
    end
    
    describe "new message" do
      let!(:sub) { FactoryBot.create(:subject, :for_wepion => true) }
      before do
        clear_emails
        sign_in root
        visit subject_path(sub)
        fill_in "MathInputNewMessage", with: "Nouveau message pour Wépion"
        check "emailWepion"
        click_button "Poster"
      end
      
      specify do
        open_email(user_in_group_A.email)
        expect(current_email.subject).to eq("Mathraining - Message à l'attention des élèves de Wépion")
        expect(current_email).to have_content("#{root.name} a posté un nouveau message sur Mathraining")
        expect(current_email).to have_link("ici", href: subject_url(sub, :host => "www.mathraining.be", :page => 1, :anchor => "bottom"))
      end
    end
  end
  
  describe "contest emails" do
    let!(:user_following_contest) { FactoryBot.create(:user) }
    let!(:user_following_subject) { FactoryBot.create(:user) }
    let!(:root) { FactoryBot.create(:root) }
  
    let!(:category) { FactoryBot.create(:category, name: "Mathraining") } # For the Forum subject
    
    let!(:running_contest) { FactoryBot.create(:contest, status: :in_progress) }
    let!(:finished_contestproblem) { FactoryBot.create(:contestproblem, contest: running_contest, number: 2, status: :in_correction, start_time: DateTime.now - 4.days, end_time: DateTime.now - 2.days) }
    let!(:finished_contestproblem_officialsol) { finished_contestproblem.contestsolutions.where(:official => true).first }
    let!(:running_contestproblem) { FactoryBot.create(:contestproblem, contest: running_contest, number: 1, status: :not_started_yet, start_time: DateTime.now + 1.day - 5.minutes, end_time: DateTime.now + 3.days, reminder_status: :no_reminder_sent) }
    let!(:running_contestproblemcheck) { FactoryBot.create(:contestproblemcheck, contestproblem: running_contestproblem) }
    let!(:running_contestsubject) { FactoryBot.create(:subject, contest: running_contest, category: category, last_comment_time: DateTime.now - 2.days) }
    
  
    before do
      user_following_contest.followed_contests << running_contest
      user_following_subject.followed_subjects << running_contestsubject
      running_contest.organizers << root
    end
    
    describe "publication of results" do
      before do
        clear_emails
        finished_contestproblem_officialsol.update_attribute(:star, true)
        sign_in root
        visit contestproblem_path(finished_contestproblem)
        click_link "Publier les résultats"
      end
      
      specify do
        open_email(user_following_subject.email)
        expect(current_email.subject).to eq("Mathraining - Nouveau message sur le sujet '#{ running_contestsubject.title }'")
        expect(current_email).to have_content("Un message automatique a été posté sur le sujet '#{ running_contestsubject.title }' que vous suivez")
        expect(current_email).to have_link("ici", href: subject_url(running_contestsubject, :host => "www.mathraining.be", :page => 1, :anchor => "bottom"))
        expect(current_email).to have_link("ici", href: unfollow_subject_url(running_contestsubject, :host => "www.mathraining.be"))
      end
    end
  
    describe "new problem in one day" do
      before do
        clear_emails
        Contest.check_contests_starts
      end
      
      specify do
        open_email(user_following_contest.email)
        expect(current_email.subject).to eq("Mathraining - Concours \##{ running_contest.number } - Problème \##{ running_contestproblem.number }")
        expect(current_email).to have_content("Pour rappel, le Problème \##{ running_contestproblem.number } du Concours \##{ running_contest.number } sera publié")
        expect(current_email).to have_link("Concours \##{ running_contest.number }", href: contest_url(running_contest, :host => "www.mathraining.be"))
        expect(current_email).to have_link("ici", href: unfollow_contest_url(running_contest, :host => "www.mathraining.be"))
      end
      
      specify do
        open_email(user_following_subject.email)
        expect(current_email.subject).to eq("Mathraining - Nouveau message sur le sujet '#{ running_contestsubject.title }'")
        expect(current_email).to have_content("Un message automatique a été posté sur le sujet '#{ running_contestsubject.title }' que vous suivez")
        expect(current_email).to have_link("ici", href: subject_url(running_contestsubject, :host => "www.mathraining.be", :page => 1, :anchor => "bottom"))
        expect(current_email).to have_link("ici", href: unfollow_subject_url(running_contestsubject, :host => "www.mathraining.be"))
      end
    end
    
    describe "new problems in one day" do
      let!(:running_contestproblem2) { FactoryBot.create(:contestproblem, contest: running_contest, number: 2, status: :not_started_yet, start_time: running_contestproblem.start_time, end_time: DateTime.now + 4.days, reminder_status: :no_reminder_sent) }
      let!(:running_contestproblemcheck2) { FactoryBot.create(:contestproblemcheck, contestproblem: running_contestproblem2) }
      let!(:running_contestproblem3) { FactoryBot.create(:contestproblem, contest: running_contest, number: 2, status: :not_started_yet, start_time: running_contestproblem.start_time, end_time: DateTime.now + 6.days, reminder_status: :no_reminder_sent) }
      let!(:running_contestproblemcheck3) { FactoryBot.create(:contestproblemcheck, contestproblem: running_contestproblem3) }
      
      before do
        clear_emails
        Contest.check_contests_starts
      end
      
      specify do
        open_email(user_following_contest.email)
        expect(current_email.subject).to eq("Mathraining - Concours \##{ running_contest.number } - Problèmes \##{ running_contestproblem.number }, \##{ running_contestproblem2.number } et \##{ running_contestproblem3.number }")
        expect(current_email).to have_content("Pour rappel, les Problèmes \##{ running_contestproblem.number }, \##{ running_contestproblem2.number } et \##{ running_contestproblem3.number } du Concours \##{ running_contest.number } seront publiés")
        expect(current_email).to have_link("Concours \##{ running_contest.number }", href: contest_url(running_contest, :host => "www.mathraining.be"))
        expect(current_email).to have_link("ici", href: unfollow_contest_url(running_contest, :host => "www.mathraining.be"))
      end
    end
  end
end
