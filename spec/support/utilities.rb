include ApplicationHelper

def sign_in(user)
  visit root_path
  fill_in "Email", with: user.email
  fill_in "Mot de passe", with: user.password
  click_button "Connexion"
end

def sign_out
	visit root_path
	click_link "Déconnexion"
end

def update_subject(sub)
	visit edit_subject_path(sub)
	fill_in "Titre", with: "Mon nouveau titre"
	fill_in "MathInput", with: "Mon nouveau message"
	click_button "Editer"
end

def create_subject(cat)
	visit new_subject_path
	select cat.name, from: "Catégorie"
	fill_in "Titre", with: "Mon titre"
	fill_in "MathInput", with: "Mon message"
	click_button "Créer"
end

def update_message(sub, mes)
	visit edit_subject_message_path(sub, mes)
	fill_in "MathInput", with: "Ma nouvelle réponse"
	click_button "Editer"
end

def create_message(sub)
	visit new_subject_message_path(sub)
	fill_in "MathInput", with: "Ma réponse"
	click_button "Poster"
end

RSpec::Matchers.define :have_error_message do |message|
  match do |page|
    page.should have_selector('div.alert.alert-error', text: message)
  end
end
