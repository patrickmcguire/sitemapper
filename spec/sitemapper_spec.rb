require 'sitemapper'

describe "Sitemapper" do
  before(:each) do
    @domain = 'example.com'
    @sitemapper = Sitemapper.new(@domain)
  end

  describe "requests" do
    before(:each) do

      @sitemapper.stub(:get_page).and_return([true, @document])
    end
  end

  describe "crawl" do
    before(:each) do
      @onsite = '/'
      @offsite = 'http://google.com'
      @onsite_subdomain = 'http://sub.example.com'
      @sitemapper.stub(:anchors).and_return([@onsite, @offsite, @onsite_subdomain])
    end

    describe "crawling subdomains" do
      before(:each) do
        @sitemapper.process_uris("http://#{@domain}", @sitemapper.anchors, Sitemapper::FOLLOW_SUBLINKS_YES)
      end

      it "should add the onsite domain" do
        @sitemapper.processing_queue.should include("http://#{@domain}#{@onsite}")
      end

      it "should not add the offsite domain" do
        @sitemapper.processing_queue.should_not include(@offsite)
      end

      it "should add the onsite subdomain" do
        @sitemapper.processing_queue.should include(@onsite_subdomain)
      end
    end

    describe "not crawling subdomains" do
      before(:each) do
        @sitemapper.crawl_subdomains = false
        @sitemapper.process_uris("http://#{@domain}", @sitemapper.anchors, Sitemapper::FOLLOW_SUBLINKS_YES)
      end

      it "should add the onsite domain" do
        @sitemapper.processing_queue.should include("http://#{@domain}#{@onsite}")
      end

      it "should not add the offsite domain" do
        @sitemapper.processing_queue.should_not include(@offsite)
      end

      it "should not add the onsite subdomain" do
        @sitemapper.processing_queue.should_not include(@onsite_subdomain)
      end
    end
  end

  describe "edge map" do
    before(:each) do
      @site = "http://#{@domain}"
      @root = "#{@site}/"
      @onsite = '/index.html'
      @offsite = 'http://google.com'
      @onsite_subdomain = "http://sub.#{@domain}"
      @css = '/application.css'
      @js = '/application.js'
      @sitemapper.stub(:anchors).and_return([@onsite, @offsite, @onsite_subdomain])
      @sitemapper.stub(:links).and_return([@css])
      @sitemapper.stub(:scripts).and_return([@js])
      @sitemapper.generate_sitemap
    end

    # they're going to be all the same, everything linked to everything else
    describe "html files" do
      describe "root url" do
        it "should have the onsite" do
          @sitemapper.edges[@root].should include("http://#{@domain}#{@onsite}")
        end

        it "should not have the offsite" do
          @sitemapper.edges[@root].should_not include(@offsite)
        end

        it "should have the onsite subdomain" do
          @sitemapper.edges[@root].should include(@onsite_subdomain)
        end

        it "should have the css" do
          @sitemapper.edges[@root].should include("#{@site}#{@css}")
        end

        it "should have the js" do
          @sitemapper.edges[@root].should include("#{@site}#{@js}")
        end
      end
    end
  end
end
