require 'test/unit'
require 'sitemapper'

class SitemapperTest < Test::Unit::TestCase
  def test_domain_assignment # mostly to make sure I have the test suite up
    domain = 'joingrouper.com'
    mapper = Sitemapper.new(domain)
    assert_equal mapper.domain, domain
  end
end
