# -*- coding: utf-8 -*-
require "spec_helper"

describe "discussions/_menu.html.erb", type: :view, discussion: true do

  let(:user) { FactoryGirl.create(:user) }
  
  before do
    assign(:current_user, user)
  end
  
  context "if the user has no discussion" do   
    it "renders no discussion" do
      render partial: "discussions/menu"
      expect(rendered).to have_link("Nouvelle discussion", href: new_discussion_path, class: "active")
      expect(rendered).to have_content("Aucune discussion")
    end
  end
  
  context "if the user has two discussions" do
    let!(:user2) { FactoryGirl.create(:user) }
    let!(:user3) { FactoryGirl.create(:user) }
    let!(:discussion12) { Discussion.create(last_message_time: DateTime.now) }
    let!(:discussion23) { Discussion.create(last_message_time: DateTime.now - 2.days) } # does not involve current user
    let!(:discussion31) { Discussion.create(last_message_time: DateTime.now - 4.days) }
    let!(:link12) { Link.create(user: user,  discussion: discussion12, nonread: 1) }
    let!(:link21) { Link.create(user: user2, discussion: discussion12, nonread: 0) }
    let!(:link23) { Link.create(user: user2, discussion: discussion23, nonread: 0) }
    let!(:link32) { Link.create(user: user3, discussion: discussion23, nonread: 0) }
    let!(:link31) { Link.create(user: user3, discussion: discussion31, nonread: 0) }
    let!(:link13) { Link.create(user: user,  discussion: discussion31, nonread: 0) }
    
    before do
      assign(:discussion, discussion31)
    end
    
    it "only renders these discussions" do
      render partial: "discussions/menu"
      expect(rendered).to have_link("Nouvelle discussion", href: new_discussion_path)
      expect(rendered).to have_link(user2.name + " (1)", href: discussion_path(discussion12), class: "list-group-item-warning")
      expect(rendered).to have_link(user3.name, href: discussion_path(discussion31), class: "active")
      expect(rendered).to have_no_link(href: discussion_path(discussion23))
    end
  end
end
