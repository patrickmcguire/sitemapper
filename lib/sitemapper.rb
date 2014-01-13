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

      status_success, page_html = get_page(current_relative_uri)
      if status_success # eventually resolves, otherwise skip
        all_anchors = anchors(page_html)
        all_links = links(page_html)
        all_scripts = scripts(page_html)

        process_uris(current_relative_uri, all_anchors, FOLLOW_SUBLINKS_YES)
        process_uris(current_relative_uri, all_links, FOLLOW_SUBLINKS_NO)
        process_uris(current_relative_uri, all_scripts, FOLLOW_SUBLINKS_NO)

        all_links = parsed_page.css('link')
      end
    end
  end

  private 
  def process_uris(current_relative_uri, hrefs, follow_sublinks)
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

  def get_page(relative_uri)
    request = Curl::Easy.new(@domain + relative_uri)
    request.follow_location = true
    request.max_redirects = 10
    status = request.perform
    [status, request.body]
  end

  def anchors(page_html)
    parsed_page = Nokogiri::HTML.parse(page_html)
    all_anchors = parsed_page.css('a')
    all_anchors.collect {|a| a.attributes['href'].value}
  end

  def links(page_html)
    parsed_page = Nokogiri::HTML.parse(page_html)
    all_links = parsed_page.css('link')
    all_links.collect {|l| l.attributes['rel'].value}
  end

  def scripts(page_html)
    parsed_page = Nokogiri::HTML.parse(page_html)
    all_scripts = parsed_page.css('script')
    all_scripts.collect {|s| s.attributes['src'].value}
  end
end
