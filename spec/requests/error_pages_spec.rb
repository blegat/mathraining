# -*- coding: utf-8 -*-
require "spec_helper"

describe "Error pages" do

  subject { page }

  describe "visitor" do
    before { visit (users_path + "wrongpath") }
    it { should have_content(error_access_refused) }
  end
end
