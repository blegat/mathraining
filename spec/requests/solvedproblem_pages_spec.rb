# -*- coding: utf-8 -*-
require "spec_helper"

describe "Solvedproblems pages" do

  subject { page }

  describe "visitor" do
    
    describe "visits recent resolutions" do
      before { visit solvedproblems_path }
      it { should have_selector("h1", text: "Résolutions récentes") }
    end
  end
end
