require 'spec_helper'

describe "theories/index" do
  before(:each) do
    assign(:theories, [
      stub_model(Theory,
        :title => "Title",
        :content => "MyText",
        :chapter_id => 1,
        :order => 2
      ),
      stub_model(Theory,
        :title => "Title",
        :content => "MyText",
        :chapter_id => 1,
        :order => 2
      )
    ])
  end

  it "renders a list of theories" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Title".to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => 2.to_s, :count => 2
  end
end
