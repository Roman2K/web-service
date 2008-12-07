require 'test_helper'

class WebService::SiteTest < Test::Unit::TestCase
  include WebService
  
  def setup
    @site = Site.new("http://example")
  end
  
  def test_url
    assert_equal "http://example", @site.url().to_s
    assert_equal "http://example", @site.url(:prefix => true).to_s
  end
  
  def test_credentials
    site = Site.new("http://example")
    assert_equal nil, site.credentials
    
    site = Site.new("http://foo@example")
    assert_equal ["foo", nil], site.credentials
    
    site = Site.new("http://foo:bar@example")
    assert_equal ["foo", "bar"], site.credentials
  end
  
  def test_url_for
    assert_equal "http://example/foo", @site.url_for("/foo").to_s
    
    @site.expects(:url).with(:public => true).returns URI("http://public")
    assert_equal "http://public/foo", @site.url_for("/foo", :public => true).to_s
  end
  
  def test_root
    assert_equal "http://example/", @site.root.to_s
  end
end

module Rails
  def self.env
    @env ||= Object.new
  end
end

class WebService::Site::SwitchTest < Test::Unit::TestCase
  include WebService
  
  def setup
    @site = Site::Switch.new("http://prod", "http://dev")
  end
  
  def test_url
    env = Rails.env
    
    def env.production?; true end
    assert_equal "http://prod", @site.url.to_s
    
    def env.production?; false end
    assert_equal "http://dev", @site.url.to_s
    assert_equal "http://prod", @site.url(:public => true).to_s
    assert_equal "http://dev", @site.url.to_s
  end
end
