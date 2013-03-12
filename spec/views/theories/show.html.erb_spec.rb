require 'spec_helper'

describe "theories/show" do
  before(:each) do
    @theory = assign(:theory, stub_model(Theory,
      :title => "Title",
      :content => "MyText",
      :chapter_id => 1,
      :order => 2
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Title/)
    rendered.should match(/MyText/)
    rendered.should match(/1/)
    rendered.should match(/2/)
  end
end
