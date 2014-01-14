require 'rspec/core/rake_task'
require 'rake'
require 'sitemapper'
require 'erb'
require 'ostruct'
require 'json'
require 'launchy'

class OurRenderer < OpenStruct
  def self.render_from_hash(t, h)
    OurRenderer.new(h).render(t)
  end

  def render(template)
    ERB.new(template).result(binding)
  end
end

RSpec::Core::RakeTask.new(:spec)

desc "Run tests"
task :default => :spec

task :show do
  site = ARGV[1]
  mapper = Sitemapper.new(site)
  mapper.generate_sitemap
  edges = mapper.edges
  cleaned_up = edges.collect do |source, targets| 
    targets.collect do |target|
      {:source => source, :target => target}
    end
  end.flatten
  template = IO.read('./views/uri.erb')
  html = OurRenderer::render_from_hash(template, {:edges => cleaned_up})
  File.open('./output.html', 'w') do |f|
    f.write(html)
  end
  Launchy::Browser.run(File.absolute_path("./output.html"))
end
