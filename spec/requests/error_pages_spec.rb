# -*- coding: utf-8 -*-
require "spec_helper"

describe "Error pages" do

  subject { page }

  describe "visitor" do
    before { visit (users_path + "wrongpath") }
    it { should have_content("Désolé... Cette page n'existe pas ou vous n'y avez pas accès.") }
  end
end
