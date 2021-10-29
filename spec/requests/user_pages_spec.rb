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
          find(:css, "#consent1[value='1']").set(true)
          find(:css, "#consent2[value='2']").set(true)
          click_button "Créer mon compte"
        end
        it { should have_selector("h1", text: "Inscription") }
        it { should have_content("erreur") }
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
        find(:css, "#consent1[value='1']").set(true)
        find(:css, "#consent2[value='2']").set(true)
      end

      specify { expect { click_button "Créer mon compte" }.to change(User, :count).by(1) }
      describe "after saving the user" do
        before { click_button "Créer mon compte" }
        it { should have_content("confirmer votre inscription") }
      end
    end
    
    describe "activates his account" do
      before do
        zero_user.email_confirm = false
        zero_user.save
      end
      
      describe "with correct key" do
        before do
          visit activate_path(:id => zero_user.id, :key => zero_user.key)
          zero_user.reload
        end
        it { should have_content("Votre compte a bien été activé !") }
        specify { expect(zero_user.email_confirm).to eq(true) }
      end
      
      describe "with incorrect key" do
        before do
          visit activate_path(:id => zero_user.id, :key => "hackingMathraining")
          zero_user.reload
        end
        it { should have_content("Le lien d'activation est erroné.") }
        specify { expect(zero_user.email_confirm).to eq(false) }
      end
      
      describe "if already active" do
        before do
          visit activate_path(:id => other_zero_user.id, :key => other_zero_user.key)
          zero_user.reload
        end
        it { should have_content("Ce compte est déjà actif !") }
        specify { expect(other_zero_user.email_confirm).to eq(true) }
      end
    end
    
    describe "forgot his password" do
      before { visit forgot_password_path }
      it { should have_selector("h1", text: "Mot de passe oublié") }
      
      describe "and enters unconfirmed email" do
        before do
          other_zero_user.email_confirm = false
          other_zero_user.save
          fill_in "Email", with: other_zero_user.email
          click_button "Envoyer l'e-mail"
        end
        it { should have_content("Veuillez d'abord confirmer votre adresse e-mail") }
      end
      
      describe "and enters incorrect email" do
        before do
          fill_in "Email", with: "nonexistingemail@hello.com"
          click_button "Envoyer l'e-mail"
        end
        it { should have_content("Aucun utilisateur ne possède cette adresse.") }
      end
      
      describe "and enters his email" do
        before do
          fill_in "Email", with: zero_user.email
          click_button "Envoyer l'e-mail"
        end
        it { should have_content("Vous allez recevoir un e-mail") }
        
        describe "and visits the reset page with wrong key" do
          before do
            visit user_recup_password_path(zero_user.id, :key => "HackingMathrainingAgain")
          end
          it { should have_content("Ce lien n'est pas valide") }
        end
        
        describe "and visits the reset page too late" do
          before do
            zero_user.reload
            zero_user.recup_password_date_limit = DateTime.now - 5000
            zero_user.save
            visit user_recup_password_path(zero_user.id, :key => zero_user.key)
          end
          it { should have_content("Ce lien n'est plus valide (il expirait après une heure)") }
        end
        
        describe "and visits the reset page if already connected" do
          before do
            zero_user.reload
            sign_in zero_user
            visit user_recup_password_path(zero_user.id, :key => zero_user.key)
          end
          it { should have_selector("h1", text: "Modifier votre mot de passe") }
        end
        
        describe "and visits the reset page" do
          before do
            zero_user.reload
            visit user_recup_password_path(zero_user.id, :key => zero_user.key)
          end
          it { should have_selector("h1", text: "Modifier votre mot de passe") }
          
          describe "and sets an empty password" do
            before { click_button "Modifier le mot de passe" }
            it { should have_content("Mot de passe est vide") }
          end
          
          describe "and sets an incorrect password" do
            before do
              page.all(:fillable_field, "Mot de passe").last.set(new_password)
              fill_in "Confirmation du mot de passe", with: "incorrect"
              click_button "Modifier le mot de passe"
            end
            it { should have_content("erreur") }
          end
          
          describe "and sets an incorrect password" do
            before do
              zero_user.recup_password_date_limit = DateTime.now - 5000
              zero_user.save
              page.all(:fillable_field, "Mot de passe").last.set(new_password)
              fill_in "Confirmation du mot de passe", with: new_password
              click_button "Modifier le mot de passe"
            end
            it { should have_content("Vous avez mis trop de temps à modifier votre mot de passe. ") }
          end
          
          describe "and sets a correct password" do
            before do
              page.all(:fillable_field, "Mot de passe").last.set(new_password)
              fill_in "Confirmation du mot de passe", with: new_password
              click_button "Modifier le mot de passe"
            end
            it { should have_content("Votre mot de passe vient d'être modifié") }
            
            describe "and tries to sign in with new password" do
              before do
                click_link "Connexion"
                fill_in "tf1", with: zero_user.email
                fill_in "tf2", with: new_password
                click_button "Connexion"
              end
              it { should have_link("Déconnexion", href: signout_path) }
            end
          end
        end
      end
    end
    
    describe "visits scores page" do
      before { visit users_path }
      it { should have_selector("h1", text: "Scores") }
      it { should have_link(ranked_user.name, href: user_path(ranked_user.id)) }
      it { should_not have_link(zero_user.name, href: user_path(zero_user.id)) }
      it { should_not have_link(admin.name, href: user_path(admin.id)) }
      it { should_not have_link(root.name, href: user_path(root.id)) }
    end
    
    describe "visits country scores page" do
      before { visit users_path(:country => country.id) }
      it { should have_link(ranked_user.name, href: user_path(ranked_user.id)) } # In country
      it { should_not have_link(other_ranked_user.name, href: user_path(other_ranked_user.id)) } # In other_country
      it { should have_link(other_ranked_user2.name, href: user_path(other_ranked_user2.id)) } # In country
    end
    
    describe "visits title scores page" do
      before { visit users_path(:title => Color.where("pt == 200").first.id) }
      it { should_not have_link(ranked_user.name, href: user_path(ranked_user.id)) } # Has 157 points
      it { should have_link(other_ranked_user.name, href: user_path(other_ranked_user.id)) } # Has 210 points
      it { should have_link(other_ranked_user2.name, href: user_path(other_ranked_user2.id)) } # Has 225 points
    end
    
    describe "visits country and title scores page" do
      before { visit users_path(:title => Color.where("pt == 200").first.id, :country => country.id) }
      it { should_not have_link(ranked_user.name, href: user_path(ranked_user.id)) } # Has 157 points and in country
      it { should_not have_link(other_ranked_user.name, href: user_path(other_ranked_user.id)) } # Has 210 points but not in country
      it { should have_link(other_ranked_user2.name, href: user_path(other_ranked_user2.id)) } # Has 225 points and in country
    end
    
    describe "tries to visit followed users" do
      before { visit followed_users_path }
      it { should have_selector("div", text: "Vous devez être connecté pour accéder à cette page.") }
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
      
      it { should have_selector("h1", text: "Actualités") }
      it { should have_selector("div.alert.alert-success") }
      it { should have_link("Déconnexion", href: signout_path) }
      specify { expect(zero_user.first_name).to eq(new_first_name) }
      specify { expect(zero_user.last_name).to eq(new_last_name) }
      specify { expect(zero_user.name).to eq(new_name) }
    end
    
    describe "tries to visit unranked scores page" do
      before { visit users_path(:title => 100) }
      it { should_not have_link(zero_user.name, href: user_path(zero_user.id)) }
    end
    
    describe "tries to visit admin scores page" do
      before { visit users_path(:title => 101) }
      it { should_not have_link(admin.name, href: user_path(admin.id)) }
    end
    
    describe "visits followed users" do
      before { zero_user.followed_users.append(ranked_user) }
      before { visit followed_users_path }
      it { should have_link(zero_user.name, href: user_path(zero_user.id)) }
      it { should have_link(ranked_user.name, href: user_path(ranked_user.id)) }
      it { should_not have_link(other_ranked_user.name, href: user_path(other_ranked_user.id)) }
    end
    
    describe "visits another user profile" do
      before { visit user_path(other_zero_user.id) }
      it { should have_link "Envoyer un message" }
      it { should have_link "Suivre" }
      
      describe "and follows him" do
        before do
          click_link("Suivre")
          visit followed_users_path
        end
        it { should have_link(other_zero_user.name, href: user_path(other_zero_user.id)) }
        
        describe "and stops to follow him" do
          before do
            visit user_path(other_zero_user.id)
            click_link "Ne plus suivre"
            visit followed_users_path
          end
          it { should_not have_link(other_zero_user.name, href: user_path(other_zero_user.id)) }
        end
      end
    end
  end

  describe "admin" do
    before { sign_in admin }

    describe "tries to delete a student" do
      before { visit user_path(zero_user) }
      it { should_not have_link("Supprimer") }
    end
    
    describe "tries to delete himself" do
      before { visit user_path(admin) }
      it { should_not have_link("Supprimer") }
    end
  end

  describe "root" do
    before { sign_in root }

    describe "deletes a student" do
      before { visit user_path(zero_user) }
      specify {	expect { click_link "Supprimer" }.to change(User, :count).by(-1) }
    end

    describe "deletes an admin" do
      before { visit user_path(admin) }
      specify { expect { click_link "Supprimer" }.to change(User, :count).by(-1) }
    end

    describe "tries to delete another root" do
      before { visit user_path(other_root) }
      it { should_not have_link("Supprimer") }
    end
    
    describe "deletes data of a student" do
      before do
        visit user_path(zero_user)
        zero_user.reload
      end
      specify { expect { click_link "Supprimer les données personnelles" and zero_user.reload }.to change{zero_user.active}.to(false) }
    end
    
    describe "deletes a student with a subject with a message (DEPENDENCY)" do
      let!(:sub) { FactoryGirl.create(:subject, user: zero_user) }
      let!(:mes) { FactoryGirl.create(:message, subject: sub, user: other_zero_user) }
      before { visit user_path(zero_user) }
      specify { expect { click_link "Supprimer" }.to change(Subject, :count).by(-1) }
      specify {	expect { click_link "Supprimer" }.to change(Message, :count).by(-1) }
    end

    describe "deletes a student with a message (DEPENDENCY)" do
      let!(:mes) { FactoryGirl.create(:message, user: zero_user) }
      before { visit user_path(zero_user) }
      specify { expect { click_link "Supprimer" }.to change(Message, :count).by(-1) }
    end

    describe "deletes a student with a discussion with tchatmessages (DEPENDENCY)" do
      before do
        create_discussion_between(zero_user, other_zero_user, "Coucou mon ami", "Salut mon poto")
        visit user_path(zero_user)
      end
      specify { expect { click_link "Supprimer" }.to change(Link, :count).by(-2) }
      specify { expect { click_link "Supprimer" }.to change(Discussion, :count).by(-1) }
      specify { expect { click_link "Supprimer" }.to change(Tchatmessage, :count).by(-2) }
    end
    
    describe "transforms user in admin" do
      before do
        visit user_path(zero_user)
        click_link("Rendre administrateur")
        zero_user.reload
      end
      specify { expect(zero_user.admin).to eq(true) }
      specify { expect(zero_user.root).to eq(false) }
    end
    
    describe "makes a user corrector" do
      before do
        visit user_path(zero_user)
        click_link("Rendre correcteur")
        zero_user.reload
      end
      specify { expect(zero_user.corrector).to eq(true) }
      specify { expect { click_link "Retirer des correcteurs" and zero_user.reload }.to change{zero_user.corrector}.to(false) }
    end
    
    describe "moves user to Wepion group" do
      before do
        visit user_path(zero_user)
        click_link("Ajouter au groupe Wépion")
        zero_user.reload
      end
      specify { expect(zero_user.wepion).to eq(true) }
      specify { expect { click_link "A" and zero_user.reload}.to change{zero_user.group}.to("A") }
      specify { expect { click_link "B" and zero_user.reload}.to change{zero_user.group}.to("B") }
      specify { expect { click_link "Retirer du groupe Wépion" and zero_user.reload }.to change{zero_user.wepion}.to(false) }
      
      describe "and remove from group A" do
        before do
          zero_user.group = "A"
          zero_user.save
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
      it { should have_content("Vous êtes maintenant dans la peau de") }
      specify { expect(root.skin).to eq(zero_user.id) }
      specify { expect { click_link "Sortir de ce corps" and root.reload }.to change{root.skin}.to(0) }
    end
    
    describe "visits unranked scores page" do
      before { visit users_path(:title => 100) }
      it { should have_link(zero_user.name, href: user_path(zero_user.id)) }
      it { should_not have_link(ranked_user.name, href: user_path(ranked_user.id)) }
    end
    
    describe "visits admin scores page" do
      before { visit users_path(:title => 101) }
      it { should have_link(admin.name, href: user_path(admin.id)) }
      it { should have_link(root.name, href: user_path(root.id)) }
      it { should_not have_link(ranked_user.name, href: user_path(ranked_user.id)) }
    end
    
    describe "visits unranked scores page from a country" do
      before { visit users_path(:title => 100, :country => country.id) }
      it { should have_link(zero_user.name, href: user_path(zero_user.id)) }
      it { should_not have_link(other_zero_user.name, href: user_path(other_zero_user.id)) }
    end
    
    describe "visits admin scores page" do
      before { visit users_path(:title => 101, :country => country.id) }
      it { should have_link(root.name, href: user_path(root.id)) }
      it { should_not have_link(other_root.name, href: user_path(other_root.id)) }
    end
  end
end
