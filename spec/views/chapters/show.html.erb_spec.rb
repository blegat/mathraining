require 'spec_helper'

describe "chapters/show" do
  before(:each) do
    @chapter = assign(:chapter, stub_model(Chapter,
      :name => "Name",
      :description => "MyText",
      :level => 1
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Name/)
    rendered.should match(/MyText/)
    rendered.should match(/1/)
  end
end
