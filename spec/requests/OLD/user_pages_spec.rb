# -*- coding: utf-8 -*-
require "spec_helper"

describe "User pages" do

  subject { page }

  let!(:country) { FactoryGirl.create(:country) }
  let!(:other_country) { FactoryGirl.create(:country) }
  let!(:zero_user) { FactoryGirl.create(:user, country: country, rating: 0) }
  let!(:other_zero_user) { FactoryGirl.create(:user, country: other_country, rating: 0) }
  let!(:ranked_user) { FactoryGirl.create(:user, country: country, rating: 157) }
  let!(:other_ranked_user) { FactoryGirl.create(:user, country: other_country, rating: 210) }
  let!(:other_ranked_user2) { FactoryGirl.create(:user, country: country, rating: 225) }
  let!(:other_ranked_user3) { FactoryGirl.create(:user, country: country, rating: 225) } # To have two users at first place (score 225)
  let!(:root) { FactoryGirl.create(:root, country: country) }
  let!(:other_root) { FactoryGirl.create(:root, country: other_country) }
  let!(:admin) { FactoryGirl.create(:admin, country: country) }
  let(:color) { FactoryGirl.create(:color, pt: 200) }
  let(:new_first_name)  { "New First Name" }
  let(:new_last_name)  { "New Last Name" }
  let(:new_name)  { "#{new_first_name} #{new_last_name}" }
  let(:new_password) { "Tototototo" }
  
  describe "visitor" do
    before { visit signup_path }

    describe "signup with invalid information" do
      specify { expect { click_button "Créer mon compte" }.not_to change(User, :count) }
      
      describe "after submission" do
        before do
          check "consent1"
          check "consent2"
          click_button "Créer mon compte"
        end
        it do
          should have_selector("h1", text: "Inscription")
          should have_error_message("erreur")
        end
      end
    end

    describe "signup with with valid information" do
      before do
        fill_in "Prénom", with: "Example"
        fill_in "Nom", with: "User"
        select country.name, from: "Pays"
        select "1977", from: "Année de naissance"
        # Il y a deux fois ces champs (pour la connexion et l"inscription)
        page.all(:fillable_field, "Adresse e-mail").last.set("user@example.com")
        fill_in "Confirmation de l'adresse e-mail", with: "user@example.com"
        page.all(:fillable_field, "Mot de passe").last.set("foobar")
        fill_in "Confirmation du mot de passe", with: "foobar"
        check "consent1"
        check "consent2"
      end

      specify { expect { click_button "Créer mon compte" }.to change(User, :count).by(1) }
      
      describe "after saving the user" do
        before { click_button "Créer mon compte" }
        specify do
          expect(page).to have_success_message("confirmer votre inscription")
          expect(User.order(:id).last.email_confirm).to eq(false)
        end
      end
    end
    
    describe "activates his account" do
      before do
        zero_user.update_attribute(:email_confirm, false)
      end
      
      describe "with correct key" do
        before do
          visit activate_path(:id => zero_user, :key => zero_user.key)
          zero_user.reload
        end
        specify do
          expect(page).to have_success_message("Votre compte a bien été activé !")
          expect(zero_user.email_confirm).to eq(true)
        end
      end
      
      describe "with incorrect key" do
        before do
          visit activate_path(:id => zero_user, :key => "hackingMathraining")
          zero_user.reload
        end
        specify do
          expect(page).to have_error_message("Le lien d'activation est erroné.")
          expect(zero_user.email_confirm).to eq(false)
        end
      end
      
      describe "if already active" do
        before do
          visit activate_path(:id => other_zero_user, :key => other_zero_user.key)
          zero_user.reload
        end
        specify do
          expect(page).to have_info_message("Ce compte est déjà actif !")
          expect(other_zero_user.email_confirm).to eq(true)
        end
      end
    end
    
    describe "forgot his password" do
      before { visit forgot_password_path }
      it { should have_selector("h1", text: "Mot de passe oublié") }
      
      describe "and enters unconfirmed email" do
        before do
          other_zero_user.update_attribute(:email_confirm, false)
          fill_in "Email", with: other_zero_user.email
          click_button "Envoyer l'e-mail"
        end
        it { should have_error_message("Veuillez d'abord confirmer votre adresse e-mail") }
      end
      
      describe "and enters incorrect email" do
        before do
          fill_in "Email", with: "nonexistingemail@hello.com"
          click_button "Envoyer l'e-mail"
        end
        it { should have_error_message("Aucun utilisateur ne possède cette adresse.") }
      end
      
      describe "and enters his email" do
        before do
          fill_in "Email", with: zero_user.email
          click_button "Envoyer l'e-mail"
        end
        it { should have_success_message("Vous allez recevoir un e-mail") }
        
        describe "and visits the reset page with wrong key" do
          before do
            visit recup_password_user_path(zero_user, :key => "HackingMathrainingAgain")
          end
          it { should have_error_message("Ce lien n'est pas valide") }
        end
        
        describe "and visits the reset page too late" do
          before do
            zero_user.reload
            zero_user.update_attribute(:recup_password_date_limit, DateTime.now - 5000)
            visit recup_password_user_path(zero_user, :key => zero_user.key)
          end
          it { should have_error_message("Ce lien n'est plus valide (il expirait après une heure)") }
        end
        
        describe "and visits the reset page if already connected" do
          before do
            zero_user.reload
            sign_in zero_user
            visit recup_password_user_path(zero_user, :key => zero_user.key)
          end
          it { should have_selector("h1", text: "Modifier votre mot de passe") }
        end
        
        describe "and visits the reset page" do
          before do
            zero_user.reload
            visit recup_password_user_path(zero_user, :key => zero_user.key)
          end
          it { should have_selector("h1", text: "Modifier votre mot de passe") }
          
          describe "and sets an empty password" do
            before { click_button "Modifier le mot de passe" }
            it { should have_error_message("Mot de passe est vide") }
          end
          
          describe "and sets an incorrect password" do
            before do
              page.all(:fillable_field, "Mot de passe").last.set(new_password)
              fill_in "Confirmation du mot de passe", with: "incorrect"
              click_button "Modifier le mot de passe"
            end
            it { should have_error_message("erreur") }
          end
          
          describe "and takes too much time to set the new password" do
            before do
              zero_user.update_attribute(:recup_password_date_limit, DateTime.now - 5000)
              page.all(:fillable_field, "Mot de passe").last.set(new_password)
              fill_in "Confirmation du mot de passe", with: new_password
              click_button "Modifier le mot de passe"
            end
            it { should have_error_message("Vous avez mis trop de temps à modifier votre mot de passe.") }
          end
          
          describe "and sets a new password while the key has been changed" do
            before do
              zero_user.update_attribute(:key, SecureRandom.urlsafe_base64)
              page.all(:fillable_field, "Mot de passe").last.set(new_password)
              fill_in "Confirmation du mot de passe", with: new_password
              click_button "Modifier le mot de passe"
            end
            it { should have_error_message("Une erreur est survenue. Il semble que votre lien pour changer de mot de passe ne soit plus valide.") }
          end
          
          describe "and sets a correct password" do
            before do
              page.all(:fillable_field, "Mot de passe").last.set(new_password)
              fill_in "Confirmation du mot de passe", with: new_password
              click_button "Modifier le mot de passe"
            end
            it { should have_success_message("Votre mot de passe vient d'être modifié") }
            
            describe "and tries to sign in with new password" do
              before do
                click_link "Connexion"
                fill_in "header_connect_email", with: zero_user.email
                fill_in "header_connect_password", with: new_password
                click_button "header_connect_button"
              end
              it { should have_link("Déconnexion", href: sessions_path) }
            end
          end
        end
      end
    end
    
    describe "visits scores page" do
      before { visit users_path }
      it do
        should have_selector("h1", text: "Scores")
        should have_link(ranked_user.name, href: user_path(ranked_user))
        should have_no_link(zero_user.name, href: user_path(zero_user))
        should have_no_link(admin.name, href: user_path(admin))
        should have_no_link(root.name, href: user_path(root))
      end
    end
    
    describe "scraps scores page" do
      before { visit users_path(:page => 3, :rank => 5) }
      it { should have_content(error_access_refused) }
    end
    
    describe "visits country scores page" do
      before { visit users_path(:country => country) }
      it do
        should have_link(ranked_user.name, href: user_path(ranked_user)) # In country
        should have_no_link(other_ranked_user.name, href: user_path(other_ranked_user)) # In other_country
        should have_link(other_ranked_user2.name, href: user_path(other_ranked_user2)) # In country
      end
    end
    
    describe "visits title scores page" do
      before { visit users_path(:title => color) }
      it do
        should have_no_link(ranked_user.name, href: user_path(ranked_user)) # Has 157 points
        should have_link(other_ranked_user.name, href: user_path(other_ranked_user)) # Has 210 points
        should have_link(other_ranked_user2.name, href: user_path(other_ranked_user2)) # Has 225 points
      end
    end
    
    describe "visits country and title scores page" do
      before { visit users_path(:title => color, :country => country) }
      it do
        should have_no_link(ranked_user.name, href: user_path(ranked_user)) # Has 157 points and in country
        should have_no_link(other_ranked_user.name, href: user_path(other_ranked_user)) # Has 210 points but not in country
        should have_link(other_ranked_user2.name, href: user_path(other_ranked_user2)) # Has 225 points and in country
      end
    end
    
    describe "tries to visit followed users" do
      before { visit followed_users_path }
      it { should have_content(error_must_be_connected) }
    end
  end

  describe "user" do
    before { sign_in zero_user }
    
    describe "edits his information" do
      before do
        visit edit_user_path(zero_user)
        fill_in "Prénom", with: new_first_name
        fill_in "Nom", with: new_last_name
        fill_in "Mot de passe", with: new_password
        fill_in "Confirmation du mot de passe", with: new_password
        click_button "Mettre à jour"
        zero_user.reload
      end
      
      specify do
        expect(page).to have_selector("h1", text: "Actualités")
        expect(page).to have_selector("div.alert.alert-success")
        expect(page).to have_link("Déconnexion", href: sessions_path)
        expect(zero_user.first_name).to eq(new_first_name)
        expect(zero_user.last_name).to eq(new_last_name)
        expect(zero_user.name).to eq(new_name)
      end
    end
    
    describe "edits his information with wrong name" do
      before do
        visit edit_user_path(zero_user)
        fill_in "Prénom", with: ""
        fill_in "Nom", with: new_last_name
        click_button "Mettre à jour"
        zero_user.reload
      end
      
      specify do
        expect(page).to have_error_message("Prénom doit être rempli")
        expect(zero_user.first_name).not_to eq("")
        expect(zero_user.last_name).not_to eq(new_last_name)
      end
    end
    
    describe "tries to edit his name while he cannot" do
      before do
        zero_user.update_attribute(:can_change_name, false)
        visit edit_user_path(zero_user)
      end
      
      it do
        should have_field("Prénom", disabled: true)
        should have_field("Nom", disabled: true)
      end        
    end
    
    describe "tries to edit his name while he cannot (with hack)" do
      before do
        visit edit_user_path(zero_user)
        zero_user.update_attribute(:can_change_name, false) # Done after the user loaded the page, so that the fields are enabled
        fill_in "Prénom", with: new_first_name
        fill_in "Nom", with: new_last_name
        click_button "Mettre à jour"
        zero_user.reload
      end
      
      specify do
        expect(page).to have_success_message("Votre profil a bien été mis à jour.")
        expect(zero_user.first_name).not_to eq(new_first_name)
        expect(zero_user.last_name).not_to eq(new_last_name)
      end
    end
    
    describe "tries to visit unranked scores page" do
      before { visit users_path(:title => 100) }
      it { should have_no_link(zero_user.name, href: user_path(zero_user)) }
    end
    
    describe "tries to visit admin scores page" do
      before { visit users_path(:title => 101) }
      it { should have_no_link(admin.name, href: user_path(admin)) }
    end
    
    describe "wants to search for a user" do
      let!(:marcel_proust) { FactoryGirl.create(:admin, first_name: "Marcel", last_name: "Proust") }
      let!(:marcel_pinot) { FactoryGirl.create(:user, first_name: "Marcel", last_name: "Pinot", rating: 200) }
      let!(:lionel_p) { FactoryGirl.create(:user, first_name: "L'ionel", last_name: "Proust", see_name: 0, rating: 100) }
      let!(:lionel_pinot) { FactoryGirl.create(:user, first_name: "L'ionel", last_name: "Pinot", rating: 0) }
      let!(:diesel_proust_inactive) { FactoryGirl.create(:user, first_name: "Diesel", last_name: "Proust", active: false) }
      
      before { visit search_users_path }
      it do
        should have_field "search"
        should have_button "Chercher"
      end
      
      describe "and search for 'EL  PROUST'" do
        before do
          fill_in "search", with: "EL  PROUST"
          click_button "Chercher"
        end
        it do
          should have_selector("h4", text: "Administrateurs")
          should have_link(marcel_proust.name, href: user_path(marcel_proust))
          should have_no_selector("h4", text: "Étudiants")
          should have_no_link(marcel_pinot.name, href: user_path(marcel_pinot))
          should have_no_link(lionel_p.name, href: user_path(lionel_p))
          should have_no_link(lionel_pinot.name, href: user_path(lionel_pinot))
          should have_no_link(diesel_proust_inactive.name, href: user_path(diesel_proust_inactive))
        end
      end
      
      describe "and search for ' el p   '" do
        before do
          fill_in "search", with: " el p   "
          click_button "Chercher"
        end
        it do
          should have_selector("h4", text: "Administrateurs")
          should have_link(marcel_proust.name, href: user_path(marcel_proust))
          should have_selector("h4", text: "Étudiants")
          should have_link(marcel_pinot.name, href: user_path(marcel_pinot))
          should have_link(lionel_p.name, href: user_path(lionel_p))
          should have_no_link(lionel_pinot.name, href: user_path(lionel_pinot)) # on page 2
          should have_no_link(diesel_proust_inactive.name, href: user_path(diesel_proust_inactive))
          should have_link(href: search_users_path(:search => " el p   ", :page => 2))
        end
        
        describe "and visits page 2" do
          before { visit search_users_path(:search => " el p   ", :page => 2) }
          it do
            should have_no_selector("h4", text: "Administrateurs") # only on page 1
            should have_no_link(marcel_proust.name, href: user_path(marcel_proust))
            should have_no_selector("h4", text: "Étudiants")
            should have_no_link(marcel_pinot.name, href: user_path(marcel_pinot)) # on page 1
            should have_no_link(lionel_p.name, href: user_path(lionel_p)) # on page 1
            should have_link(lionel_pinot.name, href: user_path(lionel_pinot))
            should have_no_link(diesel_proust_inactive.name, href: user_path(diesel_proust_inactive))
            should have_link(href: search_users_path(:search => " el p   ", :page => 1))
          end          
        end
      end
      
      describe "and search for L'ionel P." do
        before do
          fill_in "search", with: "L'ionel P."
          click_button "Chercher"
        end
        it do
          should have_no_selector("h4", text: "Administrateurs")
          should have_no_link(marcel_proust.name, href: user_path(marcel_proust))
          should have_no_selector("h4", text: "Étudiants")
          should have_no_link(marcel_pinot.name, href: user_path(marcel_pinot))
          should have_link(lionel_p.name, href: user_path(lionel_p))
          should have_no_link(lionel_pinot.name, href: user_path(lionel_pinot))
          should have_no_link(diesel_proust_inactive.name, href: user_path(diesel_proust_inactive))
        end
      end
      
      describe "and search for ' el '" do
        before do
          fill_in "search", with: " el "
          click_button "Chercher"
        end
        it do
          should have_content("Au moins 3 caractères sont nécessaires")
          should have_no_link(marcel_proust.name, href: user_path(marcel_proust))
        end
      end
      
      describe "and search for 'marcel*'" do
        before do
          fill_in "search", with: "marcel*"
          click_button "Chercher"
        end
        it do
          should have_content("Le caractère * n'est pas autorisé")
          should have_no_link(marcel_proust.name, href: user_path(marcel_proust))
        end
      end
    end
    
    describe "visits followed users" do
      before do
        zero_user.followed_users.append(ranked_user)
        visit followed_users_path
      end
      it do
        should have_selector("h1", text: "Scores")
        should have_link(zero_user.name, href: user_path(zero_user))
        should have_link(ranked_user.name, href: user_path(ranked_user))
        should have_no_link(other_ranked_user.name, href: user_path(other_ranked_user))
      end
    end
    
    describe "visits another user profile" do
      before { visit user_path(other_zero_user) }
      it do
        should have_button("Envoyer un message")
        should have_button("Suivre")
      end
      
      describe "and follows him" do
        before do
          click_button("Suivre")
          visit followed_users_path
        end
        it { should have_link(other_zero_user.name, href: user_path(other_zero_user)) }
        
        describe "and stops to follow him" do
          before do
            visit user_path(other_zero_user)
            click_button "Ne plus suivre"
            visit followed_users_path
          end
          it { should have_no_link(other_zero_user.name, href: user_path(other_zero_user)) }
        end
      end
      
      describe "and follows him but it is too much" do
        before do
          (1..30).each do |i|
            u = FactoryGirl.create(:user)
            zero_user.followed_users << u
          end
          click_button("Suivre")
        end
        it { should have_error_message("Vous ne pouvez pas suivre plus de 30 utilisateurs.") }
      end
    end
    
    describe "tries to edit the profile of another user" do
      before { visit edit_user_path(other_zero_user) }
      it { should have_content(error_access_refused) }
    end
    
    describe "tries to visit the profile of an inactive user" do
      before do
        other_zero_user.update_attribute(:active, false)
        visit user_path(other_zero_user)
      end
      it { should have_content(error_access_refused) }
    end
    
    describe "tries to visit wepion groups while not being in it" do
      before do
        zero_user.update(:wepion => false, :group => "")
        visit groups_users_path
      end
      it { should have_content(error_access_refused) }
    end
  end

  describe "admin" do
    before { sign_in admin }

    describe "tries to delete a student" do
      before { visit user_path(zero_user) }
      it { should have_no_link("Supprimer") }
    end
    
    describe "tries to delete himself" do
      before { visit user_path(admin) }
      it { should have_no_link("Supprimer") }
    end
    
    describe "visits wepion groups" do
      before do
        zero_user.update(:wepion => true, :group => "A")
        other_zero_user.update(:wepion => false, :group => "")
        visit groups_users_path
      end
      it do
        should have_selector("h1", text: "Groupes Wépion")
        should have_link(zero_user.name, href: user_path(zero_user))
        should have_no_link(other_zero_user.name)
      end
    end
  end

  describe "root" do
    before { sign_in root }

    describe "visits a student page" do
      before { visit user_path(zero_user) }
      
      specify do
        expect(page).to have_content("Connecté le")
        expect(page).to have_content(zero_user.email)
        expect(page).to have_content("Né en")
        expect { click_link "Supprimer" }.to change(User, :count).by(-1)
      end
    end

    describe "visits an admin page" do
      before { visit user_path(admin) }
      
      specify do
        expect(page).to have_content("Connecté le")
        expect(page).to have_content(admin.email)
        expect(page).to have_content("Né en")
        expect { click_link "Supprimer" }.to change(User, :count).by(-1)
      end
    end

    describe "tries to delete another root" do
      before { visit user_path(other_root) }
      it { should have_no_link("Supprimer") }
    end
    
    describe "deletes data of a student" do
      let!(:sub) { FactoryGirl.create(:subject) }
      let!(:contest) { FactoryGirl.create(:contest) }
      let!(:old_remember_token) { zero_user.remember_token }
      before do
        other_root.update_attribute(:skin, zero_user.id) # We have a root with his skin
        zero_user.followed_users << other_zero_user # He follows other_zero_user
        other_zero_user.followed_users << zero_user # He is followed by other_zero_user
        zero_user.followed_subjects << sub # He follows a subject
        zero_user.followed_contests << contest # He follows a contest
        
        visit user_path(zero_user)
        click_link "Supprimer les données personnelles"
        zero_user.reload
        other_root.reload
      end
      specify do
        expect(zero_user.active).to eq(false)
        expect(other_root.skin).to eq(0)
        expect(zero_user.followed_users.count).to eq(0)
        expect(zero_user.following_users.count).to eq(0)
        expect(zero_user.followed_subjects.count).to eq(0)
        expect(zero_user.followed_contests.count).to eq(0)
        expect(zero_user.remember_token).not_to eq(old_remember_token) # should be disconnected
      end
    end
    
    describe "deletes a student with some created stuffs" do
      let!(:mes) { FactoryGirl.create(:message, user: zero_user) }
      let!(:disc) { create_discussion_between(zero_user, other_zero_user, "Coucou mon ami", "Salut mon poto") }
      before { visit user_path(zero_user) }
      specify { expect { click_link "Supprimer" }.to change(User, :count).by(-1) .and change(Subject, :count).by(0) .and change(Message, :count).by(-1) .and change(Discussion, :count).by(-1) .and change(Link, :count).by(-2) .and change(Tchatmessage, :count).by(-2) }
    end

    describe "deletes a student while a root has his skin" do
      before do
        other_root.update_attribute(:skin, zero_user.id)
        visit user_path(zero_user)
      end
      specify { expect { click_link "Supprimer" and other_root.reload }.to change(User, :count).by(-1) .and change{other_root.skin}.to(0) }
    end
    
    describe "deletes a student with expired session (or invalid CSRF token)" do
      before do
        ActionController::Base.allow_forgery_protection = true # Don't know why but this is enough to have an invalid CSRF in testing
        visit user_path(zero_user)
        #Capybara.current_session.driver.browser.set_cookie("_session_id=wrongValue")
        click_link "Supprimer"
      end
      it do
        should have_error_message("Votre session a expiré")
        should have_content(zero_user.name) # zero_user should not be deleted
      end
      after { ActionController::Base.allow_forgery_protection = false }
    end
    
    describe "transforms user in admin" do
      before do
        visit user_path(zero_user)
        click_link("Rendre administrateur")
        zero_user.reload
      end
      specify do
        expect(zero_user.admin).to eq(true)
        expect(zero_user.root).to eq(false)
      end
    end
    
    describe "makes a user corrector" do
      before do
        visit user_path(zero_user)
        click_link("Rendre correcteur")
        zero_user.reload
      end
      specify do
        expect(zero_user.corrector).to eq(true)
        expect(zero_user.corrector_color.nil?).to eq(false)
        expect { click_link "Retirer des correcteurs" and zero_user.reload }.to change{zero_user.corrector}.to(false) .and change{zero_user.corrector_color}.to(nil)
      end
    end
    
    describe "moves user to Wepion group" do
      before do
        visit user_path(zero_user)
        click_link("Ajouter au groupe Wépion")
        zero_user.reload
      end
      specify do
        expect(zero_user.wepion).to eq(true)
        expect { click_link "A" and zero_user.reload }.to change{zero_user.group}.to("A")
        expect { click_link "B" and zero_user.reload }.to change{zero_user.group}.to("B")
        expect { click_link "Retirer du groupe Wépion" and zero_user.reload }.to change{zero_user.wepion}.to(false)
      end
      
      describe "and remove from group A" do
        before do
          zero_user.update_attribute(:group, "A")
          visit user_path(zero_user)
        end
        specify { expect { click_link "aucun" and zero_user.reload }.to change{zero_user.group}.to("") }
      end
    end
    
    describe "takes the skin of a user" do
      before do
        visit user_path(zero_user)
        click_link("Voir le site comme lui")
        root.reload
      end
      specify do
        expect(page).to have_success_message("Vous êtes maintenant dans la peau de")
        expect(root.skin).to eq(zero_user.id)
        expect { click_link "Sortir de ce corps" and root.reload }.to change{root.skin}.to(0)
      end
    end
    
    describe "forbids a user to change his name" do
      before do
        visit user_path(zero_user)
        click_link("Interdire le changement de nom")
        zero_user.reload
      end
      specify do
        expect(page).to have_success_message("Cet utilisateur ne peut maintenant plus changer son nom.")
        expect(zero_user.can_change_name).to eq(false)
      end
      
      describe "and allows him to change his name" do
        before do
          click_link("Autoriser le changement de nom")
          zero_user.reload
        end
        specify do
          expect(page).to have_success_message("Cet utilisateur peut à nouveau changer son nom.")
          expect(zero_user.can_change_name).to eq(true)
        end
      end
    end
    
    describe "visits unranked scores page" do
      before { visit users_path(:title => 100) }
      it do
        should have_link(zero_user.name, href: user_path(zero_user))
        should have_no_link(ranked_user.name, href: user_path(ranked_user))
        should have_link("Modifier les niveaux et couleurs")
      end
    end
    
    describe "visits admin scores page" do
      before { visit users_path(:title => 101) }
      it do
        should have_link(admin.name, href: user_path(admin))
        should have_link(root.name, href: user_path(root))
        should have_no_link(ranked_user.name, href: user_path(ranked_user))
      end
    end
    
    describe "visits unranked scores page from a country" do
      before { visit users_path(:title => 100, :country => country) }
      it do
        should have_link(zero_user.name, href: user_path(zero_user))
        should have_no_link(other_zero_user.name, href: user_path(other_zero_user))
      end
    end
    
    describe "visits admin scores page" do
      before { visit users_path(:title => 101, :country => country) }
      it do
        should have_link(root.name, href: user_path(root))
        should have_no_link(other_root.name, href: user_path(other_root))
      end
    end
  end
  
  describe "cron job" do
    describe "deletes user with unconfirmed email for a long time" do
      before do
        zero_user.update(:email_confirm => false,
                         :created_at => DateTime.now - 8.days)
        other_zero_user.update(:email_confirm => false,
                               :created_at => DateTime.now - 6.days)
      end
      specify { expect { User.delete_unconfirmed }.to change(User, :count).by(-1) } # Only zero_user should be deleted
    end
    
    describe "deletes user that never came for one month" do
      let!(:other_zero_user2) { FactoryGirl.create(:user, country: other_country, rating: 0) }
      before do
        zero_user.update(:created_at => DateTime.now - 40.days,
                         :last_connexion_date => "2009-01-01")
        other_zero_user.update(:created_at => DateTime.now - 20.days,
                               :last_connexion_date => "2009-01-01")
        other_zero_user2.update(:created_at => DateTime.now - 40.days,
                                :last_connexion_date => "2020-01-01")
      end
      specify { expect { User.delete_unconfirmed }.to change(User, :count).by(-1) } # Only zero_user should be deleted
    end
  end
  
  describe "command line" do
    let!(:user) { FactoryGirl.create(:user) }
    let!(:section) { FactoryGirl.create(:section, :fondation => false) }
    let!(:section2) { FactoryGirl.create(:section, :fondation => false) }
    let!(:section_fondation) { FactoryGirl.create(:section, :fondation => true) }
    let!(:chapter) { FactoryGirl.create(:chapter, :section => section, :online => true) }
    let!(:chapter_fondation) { FactoryGirl.create(:chapter, :section => section_fondation, :online => true) }
    let!(:question) { FactoryGirl.create(:exercise, :chapter => chapter, :level => 2, :online => true) }
    let!(:question2) { FactoryGirl.create(:exercise, :chapter => chapter, :level => 3, :online => true) }
    let!(:question_fondation) { FactoryGirl.create(:exercise, :chapter => chapter_fondation, :level => 4, :online => true) }
    let!(:problem) { FactoryGirl.create(:problem, :section => section2, :level => 4, :online => true) }
    let!(:problem_offline) { FactoryGirl.create(:problem, :section => section, :level => 5, :online => false) }
    let!(:submission) { FactoryGirl.create(:submission, :problem => problem, :user => user, :status => "correct") }
    let!(:solvedproblem) { FactoryGirl.create(:solvedproblem, :problem => problem, :user => user, :submission => submission) }
    let!(:solvedquestion) { FactoryGirl.create(:solvedquestion, :question => question, :user => user) }
    let!(:unsolvedquestion) { FactoryGirl.create(:unsolvedquestion, :question => question2, :user => user) }
    let!(:solvedquestion_fondation) { FactoryGirl.create(:solvedquestion, :question => question_fondation, :user => user) }
    let!(:pointspersection) { Pointspersection.create(:user => user, :section => section, :points => 0) }
    let!(:pointspersection2) { Pointspersection.create(:user => user, :section => section2, :points => 0) }
    
    describe "recomputed scores" do
      before do
        User.recompute_scores(false)
        user.reload
        section.reload
        section2.reload
      end
      specify do
        expect(user.rating).to eq(problem.value + question.value)
        expect(section.max_score).to eq(question.value + question2.value)
        expect(section2.max_score).to eq(problem.value)
        expect(user.pointspersections.where(:section => section).first.points).to eq(question.value)
        expect(user.pointspersections.where(:section => section2).first.points).to eq(problem.value)
      end
    end
  end
  
  # -- TESTS THAT REQUIRE JAVASCRIPT --
  
  describe "root", :js => true do
    before { sign_in root }
    
    describe "wants to validate the names" do
      let!(:user0) { FactoryGirl.create(:user, first_name: "Nicolas", last_name: "Benoit",      valid_name: true) }
      let!(:user1) { FactoryGirl.create(:user, first_name: "Hector",  last_name: "Dupont",      valid_name: false) }
      let!(:user2) { FactoryGirl.create(:user, first_name: "jeaN",    last_name: "boulanger",   valid_name: false) }
      let!(:user3) { FactoryGirl.create(:user, first_name: "vIcToR",  last_name: "de la Terre", valid_name: false) }
      
      before { visit validate_names_users_path }
      it do
        should have_selector("h1", text: "Valider")
        should have_no_link(user0.name, href: user_path(user0))
        should have_link(user1.name, href: user_path(user1))
        should have_link(user2.name, href: user_path(user2))
        should have_link(user3.name, href: user_path(user3))
        should have_no_link("ok-#{user0.id}")
        should have_link("ok-#{user1.id}")
        should have_link("ok-#{user2.id}")
        should have_link("ok-#{user3.id}")
        should have_no_link("capitalize-#{user0.id}")
        should have_link("capitalize-#{user1.id}")
        should have_link("capitalize-#{user2.id}")
        should have_link("capitalize-#{user3.id}")
        should have_no_link("change-#{user0.id}")
        should have_link("change-#{user1.id}")
        should have_link("change-#{user2.id}")
        should have_link("change-#{user3.id}")
      end
      
      describe "and validates one name" do
        before do
          wait_for_js_imports
          click_link "ok-#{user1.id}"
          wait_for_ajax
          user1.reload
        end
        specify do
          expect(user1.first_name).to eq("Hector")
          expect(user1.last_name).to eq("Dupont")
          expect(user1.valid_name).to eq(true)
          expect(page).to have_no_link(user1.name, href: user_path(user1)) # Should disappear
        end
      end
      
      describe "and capitalizes one name" do
        before do
          wait_for_js_imports
          click_link "capitalize-#{user2.id}"
          wait_for_ajax
          user2.reload
        end
        specify do
          expect(user2.first_name).to eq("Jean")
          expect(user2.last_name).to eq("Boulanger")
          expect(user2.valid_name).to eq(true)
          expect(page).to have_no_link(user2.name, href: user_path(user2)) # Should disappear
        end
      end
      
      describe "and use initials for one name" do
        before do
          wait_for_js_imports
          click_link "initials-#{user2.id}"
          wait_for_ajax
          user2.reload
        end
        specify do
          expect(user2.first_name).to eq("J.")
          expect(user2.last_name).to eq("B.")
          expect(user2.valid_name).to eq(true)
          expect(page).to have_no_link(user2.name, href: user_path(user2)) # Should disappear
        end
      end
      
      describe "and passes one name" do
        before do
          wait_for_js_imports
          click_link "pass-#{user2.id}"
          wait_for_ajax
          user2.reload
        end
        specify do
          expect(user2.first_name).to eq("jeaN")
          expect(user2.last_name).to eq("boulanger")
          expect(user2.valid_name).to eq(false)
          expect(page).to have_no_link(user2.name, href: user_path(user2)) # Should disappear
        end
      end
      
      describe "and clicks to change one name" do
        before do
          wait_for_js_imports
          click_link "change-#{user3.id}"
          wait_for_ajax
          user3.reload
        end
        specify do
          expect(page).to have_field("first-name-#{user3.id}", with: user3.first_name)
          expect(page).to have_field("last-name-#{user3.id}", with: user3.last_name)
          expect(page).to have_link("confirm-#{user3.id}")
        end
        
        describe "and fixes the name" do
          before do
            fill_in "first-name-#{user3.id}", with: "Victor"
            fill_in "last-name-#{user3.id}", with: "de la Terre"
            click_link "confirm-#{user3.id}"
            wait_for_ajax
            user3.reload
          end
          specify do
            expect(user3.first_name).to eq("Victor")
            expect(user3.last_name).to eq("de la Terre")
            expect(user3.valid_name).to eq(true)
            expect(page).to have_no_link(user3.name, href: user_path(user3)) # Should disappear
          end
        end
      end
    end
  end
end
