require 'rspec/core/rake_task'
require 'rake'
require 'sitemapper'

RSpec::Core::RakeTask.new(:spec)

desc "Run tests"
task :default => :spec

task :show do
  options = {}
  OptionParser.new(args) do |opts|
    opts.banner = "Usage: rake show -s [site]"
    opts.on("-s", "--site {site}", "Site to crawl", String) do |site|
      options[:site] = site
    end
  end.parse!

  Sitemapper.new(options[:site])
  Sitemapper.generate_sitemap
  Sitemapper.show_in_browser
end
