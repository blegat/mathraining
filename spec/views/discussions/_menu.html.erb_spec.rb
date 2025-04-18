# -*- coding: utf-8 -*-
require "spec_helper"

describe "discussions/_menu.html.erb", type: :view, discussion: true do

  subject { rendered }

  let(:user) { FactoryBot.create(:user) }
  
  before { sign_in_view(user) }
  
  context "if the user has no discussion" do   
    it "renders no discussion" do
      render partial: "discussions/menu"
      should have_link("Nouvelle discussion", href: new_discussion_path, class: "active")
      should have_content("Aucune discussion")
    end
  end
  
  context "if the user has two discussions" do
    let!(:user2) { FactoryBot.create(:user) }
    let!(:user3) { FactoryBot.create(:user) }
    let!(:discussion12) { Discussion.create(last_message_time: DateTime.now) }
    let!(:discussion23) { Discussion.create(last_message_time: DateTime.now - 2.days) } # does not involve current user
    let!(:discussion31) { Discussion.create(last_message_time: DateTime.now - 4.days) }
    let!(:link12) { Link.create(user: user,  discussion: discussion12, nonread: 1) }
    let!(:link21) { Link.create(user: user2, discussion: discussion12, nonread: 0) }
    let!(:link23) { Link.create(user: user2, discussion: discussion23, nonread: 0) }
    let!(:link32) { Link.create(user: user3, discussion: discussion23, nonread: 0) }
    let!(:link31) { Link.create(user: user3, discussion: discussion31, nonread: 0) }
    let!(:link13) { Link.create(user: user,  discussion: discussion31, nonread: 0) }
    
    before { assign(:discussion, discussion31) }
    
    it "only renders these discussions" do
      render partial: "discussions/menu"
      should have_link("Nouvelle discussion", href: new_discussion_path)
      should have_link(user2.name + " (1)", href: discussion_path(discussion12), class: "list-group-item-warning")
      should have_link(user3.name, href: discussion_path(discussion31), class: "active")
      should have_no_link(href: discussion_path(discussion23))
    end
  end
end
