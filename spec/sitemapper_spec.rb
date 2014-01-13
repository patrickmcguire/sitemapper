require 'sitemapper'

describe "Sitemapper" do
  before(:each) do
    @domain = 'example.com'
    @sitemapper = Sitemapper.new(@domain)
  end

  describe "requests" do
    
  end

  it "should have the right domain" do 
    @sitemapper.domain.should == @domain
  end
end
