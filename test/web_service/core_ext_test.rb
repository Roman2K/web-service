require "test_helper"

class CoreExtTest < Test::Unit::TestCase
  def test_uri_obfuscate
    assert_equal "http://example.com", URI("http://example.com").obfuscate.to_s
    assert_equal "http://***@example.com", URI("http://foo@example.com").obfuscate.to_s
    assert_equal "http://***:***@example.com", URI("http://foo:secret@example.com").obfuscate.to_s
  end
  
  def test_cgi_escape
    assert_equal "example%2ecom", CGI.escape("example.com")
  end
end
