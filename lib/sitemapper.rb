require 'set'
require 'public_suffix'
require 'uri'
require 'capybara'
require 'capybara/dsl'
require 'capybara-webkit'

Capybara.run_server = false
Capybara.current_driver = :webkit

class Sitemapper
  include Capybara::DSL
  FOLLOW_SUBLINKS_YES = 1
  FOLLOW_SUBLINKS_NO = 2

  attr_accessor :domain, :crawl_subdomains, :edges, :seen_resources, :processing_queue

  def initialize(domain, crawl_subdomains=true)
    @domain = domain.chomp('/')
    @crawl_subdomains = crawl_subdomains
    @edges = {}
    @seen_resources = Set.new
    @processing_queue = ["http://#{domain}/"]
  end

  def generate_sitemap
    while not @processing_queue.empty?
      puts "#{@seen_resources.size}/#{@seen_resources.size + @processing_queue.size}"
      current_uri = @processing_queue.shift
      next if @seen_resources.include? current_uri
      @seen_resources << current_uri

      all_anchors = anchors(current_uri)
      all_links = links(current_uri)
      all_scripts = scripts(current_uri)

      process_uris(current_uri, all_anchors, FOLLOW_SUBLINKS_YES)
      process_uris(current_uri, all_links, FOLLOW_SUBLINKS_NO)
      process_uris(current_uri, all_scripts, FOLLOW_SUBLINKS_NO)
    end
  end
  
  def process_uris(current_uri, uris, follow_sublinks)
    @edges[current_uri] ||= Set.new
    uris.each do |uri|
      begin
        wrapped_uri = URI(uri)
        next if wrapped_uri.is_a? URI::MailTo
      rescue URI::InvalidURIError => e
        puts "#{uri} failed"
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
          begin
            @edges[current_uri] << uri
          rescue Exception => e
            puts current_uri
            puts @edges.inspect
            exit
          end
        end

        if on_our_domain and not @seen_resources.include? uri and follow_sublinks == FOLLOW_SUBLINKS_YES
          @processing_queue << uri
        end
      else
        uri_to_add = "http://#{domain_to_prepend}#{uri}"
        @edges[current_uri] << uri_to_add
        if not seen_resources.include? uri and follow_sublinks == FOLLOW_SUBLINKS_YES
          @processing_queue << uri_to_add
        end
      end
    end
  end
  
  def anchors(absolute_uri)
    query_filter(absolute_uri, 'a', :href)
  end

  def links(absolute_uri)
    query_filter(absolute_uri, 'link', :rel)
  end

  def scripts(absolute_uri)
    query_filter(absolute_uri, 'script', :src)
  end

  def query_filter(absolute_uri, query, attribute_symbol)
    wrapped_uri = URI(absolute_uri)
    Capybara.app_host = "http://#{wrapped_uri.host}"
    visit(wrapped_uri.request_uri)
    all_items = all(query)
    all_items_extracted = all_items.collect {|i| i[attribute_symbol]}
    all_items_extracted.reject {|i| i.nil?}
  end
end
