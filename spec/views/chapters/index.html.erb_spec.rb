require 'spec_helper'

describe "chapters/index" do
  before(:each) do
    assign(:chapters, [
      stub_model(Chapter,
        :name => "Name",
        :description => "MyText",
        :level => 1
      ),
      stub_model(Chapter,
        :name => "Name",
        :description => "MyText",
        :level => 1
      )
    ])
  end

  it "renders a list of chapters" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
    assert_select "tr>td", :text => 1.to_s, :count => 2
  end
end
