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

def update_subject(sub, newtitle, newcontent)
	visit edit_subject_path(sub)
	fill_in "Titre", with: newtitle
	fill_in "MathInput", with: newcontent
	click_button "Editer"
end

def create_subject(cat, title, content)
	visit new_subject_path
	select cat.name, from: "Catégorie"
	fill_in "Titre", with: title
	fill_in "MathInput", with: content
	click_button "Créer"
end

def update_message(sub, mes, newcontent)
	visit edit_subject_message_path(sub, mes)
	fill_in "MathInput", with: newcontent
	click_button "Editer"
end

def create_message(sub, content)
	visit new_subject_message_path(sub)
	fill_in "MathInput", with: content
	click_button "Poster"
end

def create_discussion(user, content)
	visit new_discussion_path
	select user.name, from: "destinataire"
	fill_in "MathInput", with: content
	click_button "Envoyer"
end

def create_discussion_between(user1, user2, content1, content2)
	d = Discussion.new
	d.last_message = DateTime.now
	d.save
	link = Link.new
  link.user_id = user1.id
  link.discussion_id = d.id
  link.nonread = 0
  link.save
  link2 = Link.new
  link2.user_id = user2.id
  link2.discussion_id = d.id
  link2.nonread = 0
  link2.save
  m = Tchatmessage.new
  m.user_id = user1.id
  m.content = content1
  m.discussion_id = d.id
  m.save
  m2 = Tchatmessage.new
  m2.user_id = user2.id
  m2.content = content2
  m2.discussion_id = d.id
  m2.save
  return d
end

def answer_discussion(content) # Should be on the page of the discussion!
	fill_in "MathInput", with: content
	click_button "Envoyer"
end

RSpec::Matchers.define :have_error_message do |message|
  match do |page|
    page.should have_selector('div.alert.alert-error', text: message)
  end
end
