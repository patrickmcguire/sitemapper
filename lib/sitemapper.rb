require 'curb'
require 'set'
require 'nokogiri'
require 'public_suffix'
require 'uri'

class Sitemapper
  FOLLOW_SUBLINKS_YES = 1
  FOLLOW_SUBLINKS_NO = 2

  attr_accessor :domain, :crawl_subdomain, :edges, :seen_resources, :processing_queue

  def initialize(domain, crawl_subdomains=true)
    @domain = domain.chomp('/')
    @crawl_subdomains = crawl_subdomains
    @edges = {}
    @seen_resources = Set.new
    @processing_queue = ["http://#{domain}/"]
  end

  def generate_sitemap
    while not @processing_queue.empty?
      current_uri = @processing_queue.shift
      @seen_resources << current_uri
      @edges[current_uri] = []

      status_success, page_html = get_page(current_uri)
      if status_success # eventually resolves, otherwise skip
        all_anchors = anchors(page_html)
        all_links = links(page_html)
        all_scripts = scripts(page_html)

        process_uris(current_uri, all_anchors, FOLLOW_SUBLINKS_YES)
        process_uris(current_uri, all_links, FOLLOW_SUBLINKS_NO)
        process_uris(current_uri, all_scripts, FOLLOW_SUBLINKS_NO)
      end
    end
  end

  private 
  def process_uris(current_uri, uris, follow_sublinks)
    uris.each do |uri|
      begin
        wrapped_uri = URI(uri)
        next if wrapped_uri.is_a? URI::MailTo
      rescue URI::InvalidURIError => e
        puts "#{uri} failed"
        exit
        next
      end

      wrapped_current_uri = URI(current_uri)
      parsed_current_domain = PublicSuffix.parse(wrapped_current_uri.host)
      domain_to_prepend = parsed_current_domain.domain

      if wrapped_uri.absolute?
        uri_to_add = uri
        on_our_domain = if wrapped_uri.absolute? 
                          if not @crawl_subdomains 
                            wrapped_uri.host == @domain
                          else
                            begin
                              parsed_domain = PublicSuffix.parse(wrapped_uri.host)
                              parsed_domain.domain == @domain
                            rescue Exception => e
                              puts e
                              puts wrapped_uri.inspect
                              next
                            end
                          end
                        end

        if on_our_domain
          @edges[current_uri] << uri
        end

        if on_our_domain and not @seen_resources.include? uri and follow_sublinks == FOLLOW_SUBLINKS_YES
          @processing_queue << uri
        end
      else
        uri_to_add = "http://#{domain_to_prepend}#{uri}"
        if not seen_resources.include? uri and follow_sublinks == FOLLOW_SUBLINKS_YES
          @processing_queue << uri_to_add
        end
      end
    end
  end

  def get_page(absolute_uri)
    request = Curl::Easy.new(absolute_uri)
    request.follow_location = true
    request.max_redirects = 10
    begin
      status = request.perform
      [status, request.body]
    rescue Exception => e
      puts absolute_uri 
      puts e.backtrace
      [false, ""]
    end
  end

  def anchors(page_html)
    parsed_page = Nokogiri::HTML.parse(page_html)
    all_anchors = parsed_page.css('a')
    all_anchors.collect do |a|
      begin
        a.attributes['href'].value
      rescue Exception => e
        puts a.inspect
        puts e.backtrace
        next
      end
    end.reject {|a| a.nil?}
  end

  def links(page_html)
    parsed_page = Nokogiri::HTML.parse(page_html)
    all_links = parsed_page.css('link')
    all_links.collect {|l| l.attributes['rel'].value}
  end

  def scripts(page_html)
    parsed_page = Nokogiri::HTML.parse(page_html)
    all_scripts = parsed_page.css('script')
    not_inline = all_scripts.reject {|s| not s.attributes['src']}
    not_inline.collect do |s| 
      begin 
        s.attributes['src'].value
      rescue Exception => e
        puts "offending node"
        puts s.inspect
        puts e.backtrace
        puts "/offending node"
      end
    end
  end
end
