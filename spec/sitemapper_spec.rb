require 'sitemapper'

describe "Sitemapper" do
  before(:each) do
    @domain = 'example.com'
    @sitemapper = Sitemapper.new(@domain)
  end

  describe "requests" do
    before(:each) do
      @offsite = 'http://wikipedia.org'
      @onsite_rel = '/morestuff'
      @onsite_absolute = 'http://example.com/morestuff'
      @onsite_subdomain = 'http://subdomain.example.com/morestuff'

      @offsite_css = 'http://netdna.bootstrapcdn.com/bootstrap/3.0.3/css/bootstrap.min.css'
      @onsite_rel_css = '/stylesheet.css'
      @onsite_absolute_css = 'http://example.com/stylesheet.css'
      @onsite_subdomain_css = 'http://subdomain.example.com/stylesheet.css'

      @offsite_js = 'http://netdna.bootstrapcdn.com/bootstrap/3.0.3/css/bootstrap.min.js'
      @onsite_rel_js = '/application.js'
      @onsite_absolute_js = 'http://example.com/application.js'
      @onsite_subdomain_js = 'http://subdomain.example.com/application.js'

      @document = <<EOS
      <html>
        <head>
          <link rel="#{@offsite_css}" />
          <link rel="#{@onsite_rel_css}" />
          <link rel="#{@onsite_absolute_css}" />
          <link rel="#{@onsite_subdomain_css}" />
          <script src="#{@offsite_js}" type="text/javascript"></script>
          <script src="#{@onsite_rel_js}" type="text/javascript"></script>
          <script src="#{@onsite_absolute_js}" type="text/javascript"></script>
          <script src="#{@onsite_subdomain_js}" type="text/javascript"></script>
        </head>
        <body>
          <a href="#{@offsite}"></a>
          <a href="#{@onsite_rel}"></a>
          <a href="#{@onsite_absolute}"></a>
          <a href="#{@onsite_subdomain}"></a>
        </body>
      </html>
EOS

      @sitemapper.stub(:get_page).and_return([true, @document])
    end

    # making sure my data is what I think it is
    describe "has the right elements" do
      it "should have the offsite anchor" do
        (@sitemapper.send(:anchors, @document).include? @offsite).should be_true
      end

      it "shouuld have the rel anchor" do
        (@sitemapper.send(:anchors, @document).include? @onsite_rel).should be_true
      end

      it "should have the absolute anchor" do
        (@sitemapper.send(:anchors, @document).include? @onsite_absolute).should be_true
      end

      it "should have the subdomain anchor" do
        (@sitemapper.send(:anchors, @document).include? @onsite_subdomain).should be_true
      end

      it "should have the offsite link" do
        (@sitemapper.send(:links, @document).include? @offsite_css).should be_true
      end

      it "shouuld have the rel link" do
        (@sitemapper.send(:links, @document).include? @onsite_rel_css).should be_true
      end

      it "should have the absolute link" do
        (@sitemapper.send(:links, @document).include? @onsite_absolute_css).should be_true
      end

      it "should have the subdomain link" do
        (@sitemapper.send(:links, @document).include? @onsite_subdomain_css).should be_true
      end

      it "should have the offsite script" do
        (@sitemapper.send(:scripts, @document).include? @offsite_js).should be_true
      end

      it "shouuld have the rel script" do
        (@sitemapper.send(:scripts, @document).include? @onsite_rel_js).should be_true
      end

      it "should have the absolute script" do
        (@sitemapper.send(:scripts, @document).include? @onsite_absolute_js).should be_true
      end

      it "should have the subdomain script" do
        (@sitemapper.send(:scripts, @document).include? @onsite_subdomain_js).should be_true
      end
    end
  end

  describe "crawl" do

  end
end
