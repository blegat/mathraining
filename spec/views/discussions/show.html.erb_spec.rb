# -*- coding: utf-8 -*-
require "spec_helper"

describe "discussions/show.html.erb", type: :view, discussion: true do

  subject { rendered }

  let(:user) { FactoryGirl.create(:user) }
  let(:user2) { FactoryGirl.create(:user) }
  let!(:discussion) { Discussion.create(last_message_time: DateTime.now) }
  let!(:link1) { Link.create(user: user,  discussion: discussion, nonread: 1) }
  let!(:link2) { Link.create(user: user2, discussion: discussion, nonread: 0) }
  let!(:tchatmessage1) { Tchatmessage.create(user: user, discussion: discussion, content: "Coucou", created_at: DateTime.now - 5.days) }
  let!(:tchatmessage2) { Tchatmessage.create(user: user2, discussion: discussion, content: "Hello", created_at: DateTime.now - 3.days) }
  
  before do
    sign_in_view(user)
    assign(:discussion, discussion)
    assign(:tchatmessage, Tchatmessage.new)
    assign(:compteur, 1) # defined by controller
  end
  
  context "if the other user is active" do    
    it "renders the discussion page correctly" do
      render template: "discussions/show", locals: {params: {id: discussion.id}}
      expect(response).to render_template(:partial => "discussions/_menu")
      should have_selector("h3", text: "Discussion avec #{user2.name}")
      should have_field("MathInput")
      should have_button("Envoyer")
      should have_no_content("Ce compte a été supprimé")
      expect(response).to render_template(:partial => "tchatmessages/_show", :locals => {m: tchatmessage2})
      expect(response).to render_template(:partial => "tchatmessages/_show", :locals => {m: tchatmessage1})
    end
  end
  
  context "if the other user is unactive" do
    before { user2.update_attribute(:active, false) }
    
    it "renders the discussion page correctly" do
      render template: "discussions/show", locals: {params: {id: discussion.id}}
      expect(response).to render_template(:partial => "discussions/_menu")
      should have_selector("h3", text: "Discussion avec #{user2.name}")
      should have_no_field("MathInput")
      should have_no_button("Envoyer")
      should have_content("Ce compte a été supprimé")
      expect(response).to render_template(:partial => "tchatmessages/_show", :locals => {m: tchatmessage2})
      expect(response).to render_template(:partial => "tchatmessages/_show", :locals => {m: tchatmessage1})
    end
  end
end
