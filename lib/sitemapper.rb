require 'curb'
require 'set'
require 'nokogiri'
require 'public_suffix'

class Sitemapper
  FOLLOW_SUBLINKS_YES = 1
  FOLLOW_SUBLINKS_NO = 2

  attr_accessor :domain, :crawl_subdomain, :edges, :seen_resources, :processing_queue

  def initialize(domain, crawl_subdomains=true)
    @domain = domain.chomp('/')
    @crawl_subdomains = crawl_subdomains
    @edges = {}
    @seen_resources = Set.new
    @processing_queue = ['/']
  end

  def generate_sitemap
    while not @processing_queue.empty?
      current_relative_uri = @processing_queue.shift
      @seen_resources << current_relative_uri
      @edges[current_relative_uri] = []

      request = Curl::Easy.new(@domain + current_relative_uri)
      request.follow_location = true
      request.max_redirects = 10

      if request.perform # eventually resolves, otherwise skip
        page_html = request.body
        parsed_page = Nokogiri::HTML.parse(page_html)
        all_anchors = parsed_page.css('a')
        all_links = parsed_page.css('link')

        process_uris(current_relative_uri, all_anchors, FOLLOW_SUBLINKS_YES)
        process_uris(current_relative_uri, all_links, FOLLOW_SUBLINKS_NO)

        all_links = parsed_page.css('link')
      end

      case response.response_code
      when 200

      when 301

      when 302
      end
    end
  end

  private 
  def process_hrefs(current_relative_uri, hrefs, follow_sublinks)
    hrefs.each do |href|
      attributes = href.attributes
      uri = attributes['href'].value
      wrapped_uri = URI(uri)

      on_our_domain = if wrapped_uri.absolute? 
                        if not @crawl_subdomains 
                          wrapped_uri.host == @domain
                        else
                          parsed_domain = PublicSuffix.parse(uri)
                          parsed_domain.domain == @domain
                        end
                      end

      if on_our_domain
        @edges[current_relative_uri] << uri
      end

      if on_our_domain and not @seen_resources.include? uri and follow_sublinks == FOLLOW_SUBLINKS::TRUE
        @process_queue << uri
      end
    end
  end
end
