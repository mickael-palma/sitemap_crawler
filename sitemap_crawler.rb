#!/usr/bin/env ruby
# encoding: utf-8
require 'rubygems'
require "em-synchrony"
require "em-synchrony/em-http"
require "em-synchrony/fiber_iterator"
require 'nokogiri'
require 'open-uri'
require 'benchmark'
require 'json'
require 'debugger'
require 'anemone'
require 'optparse'
require 'builder'
require 'sqlite3'
require 'uri'

class SitemapCrawler
  def initialize(options={})
    @options  = options
    @products = []
    @errors   = []
  end

  PRODUCT_ATTRIBUTES = %w{ title brand category link medias price sale_price shipping_price availability description 
                          ean condition mpn isbn color size online_only review_score }

  LIGHT_PRODUCT_ATTRIBUTES = %w{ title brand category link medias price }
  
  def urls
    hostname     = "#{@options[:hostname]}:#{@options[:port]}"
    website_name = @options[:website]
    filter       = @options[:filter]

    req = EventMachine::HttpRequest.new(hostname).get :query => { :name => website_name, :sitemap_url => '' }, :connect_timeout => 10,
                                                                                                               :inactivity_timeout => 29
    resp = req.response
    urls = JSON.parse(resp)['urls']

    urls = urls.select { |url| url =~ filter } unless filter.nil?

    if ARGV[0] == "urls"
      urls.each { |url| p url }
      p "--------------------------------------------"
      p " We found #{urls.size} urls"
      p "--------------------------------------------"
    else
      urls
    end
  end

  def get_product(url)
    hostname     = "#{@options[:hostname]}:#{@options[:port]}"
    website_name = @options[:website]

    req  = EventMachine::HttpRequest.new(hostname).get :query => { :name => website_name, :product_url => url }
    resp = req.response

    req.callback {

      products = JSON.parse(resp)["products"]
      
      if products.nil?
        @errors.push url
        p "#{url} is not a product URL"
      else
        product  = products.first 
      
        unless product['errors']
          @products.push url
          p url
          display_product(product)
        end
      end
    }
    req.errback { @errors.push url }
  end

  def crawl_it
    url = @options[:url]

    get_product(url)    
  end

  def crawl_all
    hostname     = "#{@options[:hostname]}:#{@options[:port]}"
    website_name = @options[:website]
    concurrency  = @options[:concurrency]
    products     = []
    
    EM::Synchrony::FiberIterator.new(urls, concurrency).each do |url|
      get_product(url)
    end

    p "--------------------------------------------"
    p " We found #{@products.size} products"
    p "--------------------------------------------"

    p "--------------------------------------------"
    p " We found #{@errors.size} bad/non-product url"
    p "--------------------------------------------"
  end

  def search
    hostname     = "#{@options[:hostname]}:#{@options[:port]}"
    website_name = @options[:website]
    term         = @options[:term]

    req  = EventMachine::HttpRequest.new(hostname).get :query => { :name => website_name, :term => term }
    resp = req.response

    req.callback {

      products = JSON.parse(resp)["products"]
      
      if products.nil?
        p "#{url} is not a product URL"
      else 
        unless products.first['errors']
          products.each do |product|
            display_product(product)
          end

          p "--------------------------------------------"
          p " We found #{products.size} products"
          p "--------------------------------------------"
        end
      end
    }
    req.errback { errors.push url }
  end

  def display_product(product)
    layout = @options[:layout]

    attributes = layout == "normal" ? PRODUCT_ATTRIBUTES : LIGHT_PRODUCT_ATTRIBUTES

    p "-------------------------------------------"
    p ""
    attributes.each do |attr|
      p "#{attr} : #{product[attr]}"
    end
    p ""
    p "-------------------------------------------"
  end

  def sitemap
    website_name        = @options[:website]
    url                 = @options[:url]
    threads             = @options[:threads]
    skip_query_strings  = @options[:query]
    obey_robots_txt     = @options[:robot]
    sitemap             = ""
    clean_directory
    
    xml                 = Builder::XmlMarkup.new(:target => sitemap, :indent=>2)
    xml.instruct!
    xml.urlset(:xmlns=>'http://www.sitemaps.org/schemas/sitemap/0.9') {
      Anemone.crawl(url, :threads => threads,
                         :discard_page_bodies => true,
                         :skip_query_strings => skip_query_strings,
                         :obey_robots_txt => obey_robots_txt) do |anemone|

        anemone.storage = Anemone::Storage.SQLite3("sitemaps/#{website_name}.db")
        anemone.skip_links_like skip_regexp
        
        anemone.on_every_page do |page|
          p page.url
          xml.url {
            xml.loc(page.url)
            xml.lastmod(Time.now.utc.strftime("%Y-%m-%dT%H:%M:%S+00:00"))
            xml.changefreq('weekly')
          }        
        end
      end
    }
    File.open("sitemaps/#{website_name}.xml", 'w') do |f|
      f.write sitemap
    end
  end

  def skip_regexp
    default_skip = Regexp.union(%w{ .csv .doc .docx .gif .jpg .JPG .jpeg .js .mp3 .mp4 .mpg .mpeg .pdf .png .ppt .rss .swf .txt .xls .xlst .xml })
    
    if @options[:skip].nil?
      default_skip
    else
      Regexp.union(@options[:skip], default_skip)
    end
  end

  def clean_directory
    website_name = @options[:website]
    directory    = "sitemaps"
    files = ["#{directory}/#{website_name}.db", "#{directory}/#{website_name}.xml"]
    
    files.each { |f| File.delete(f) if File.exists?(f) }
  end
end

COMMANDS   = %w{ urls crawl_all crawl_it search }
URL_REGEXP = URI::regexp

options = {}

opt_parser = OptionParser.new do |opt|
  opt.banner = "Usage: #{$PROGRAM_NAME} COMMAND [OPTIONS]"
  opt.separator  ""
  opt.separator  "Commands"
  opt.separator  "     urls: get all urls from sitemap"
  opt.separator  "     crawl_all: crawl every sitemap url"
  opt.separator  "     crawl_it: crawl one url"
  opt.separator  "     search: query website search engine"
  opt.separator  "     sitemap: generate a sitemap. -u and -w are required"
  opt.separator  ""
  opt.separator  "Options"


  options[:threads] = 4
  opt.on("-T","--threads=THREADS", Integer, "how many threads you want to use for sitemap command. Default is : 4") do |threads|
    options[:threads] = threads
  end

  options[:robot] = true
  opt.on("-r","--robot", "don't obey the robots exclusion protocol. Default is : true") do |robot|
    options[:robot] = false
  end

  options[:query] = true
  opt.on("-q","--query", "for sitemap command skip any link with a query string? e.g. http://foo.com/?u=user. Default is : true") do |query|
    options[:query] = false
  end

  opt.on("-s","--skip=SKIP", Regexp, "filter for sitemap command. Use Regex to define URLs which should not be followed") do |skip|
    options[:skip] = skip
  end

  opt.on("-f","--filter=FILTER", Regexp,"filter for sitemap URLs using Regular Expressions") do |filter|
    options[:filter] = filter
  end

  options[:layout] = "normal"
  opt.on("-l","--layout=LAYOUT", %w{ normal light }, "you can change the product display layout. 'normal' and 'light' are available. Default is : normal") do |layout|
    options[:layout] = layout
  end

  opt.on("-t","--term=TERM","term you want to search for with the search command") do |term|
    options[:term] = term
  end

  opt.on("-w","--website=NAME","website name you want to focus on") do |name|
    options[:website] = name
  end

  opt.on("-u","--url=URL", URL_REGEXP,"URL you want to crawl with crawl_it or sitemap command. Ex: http://www.test.com") do |url|
    options[:url] = url.first
  end

  options[:concurrency] = 25
  opt.on("-c","--concurrency=CONCURRENCY", Integer,"how many request per second. Default is : 25") do |concurrency|
    options[:concurrency] = concurrency
  end

  options[:port] = 5001
  opt.on("-p","--port=PORT", Integer,"spypp_server port. Default is : 5001") do |port|
    options[:port] = port
  end

  options[:hostname] = "http://0.0.0.0"
  opt.on("-h","--host=HOSTNAME", URL_REGEXP,"hostname of the spypp_server. Default is : http://0.0.0.0") do |hostname|
    options[:hostname] = hostname.first
  end

  opt.on("--help","--help","show this help, then exit") do 
    puts opt_parser
  end
end

opt_parser.parse!

if ARGV.empty?
  p opt_parser
elsif ARGV[0] == "sitemap"
  time = Benchmark.measure do
    SitemapCrawler.new(options).send(ARGV[0])
  end
  p time
else
  if COMMANDS.include?(ARGV[0])
    time = Benchmark.measure do
      EM.synchrony do
        SitemapCrawler.new(options).send(ARGV[0])
        EventMachine.stop
      end
    end
    p time
  else
    p opt_parser
  end
end