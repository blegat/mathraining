include ApplicationHelper

def sign_in(user)
  visit root_path
  click_link "Connexion"
  fill_in "tf1", with: user.email
  fill_in "tf2", with: user.password
  click_button "Connexion"
end

def sign_out
  visit root_path
  click_link "Déconnexion"
end

def error_access_refused
  return "Désolé... Cette page n'existe pas ou vous n'y avez pas accès."
end

def error_must_be_connected
  return "Vous devez être connecté pour accéder à cette page."
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

RSpec::Matchers.define :have_error_message do |message|
  match do |page|
    page.should have_selector("div.alert.alert-error", text: message)
  end
end
