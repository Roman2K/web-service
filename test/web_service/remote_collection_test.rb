require 'test_helper'

class WebService::RemoteCollectionTest < Test::Unit::TestCase
  def setup
    @resource_details = Object.new
    @collection = WebService::RemoteCollection.new(@resource_details)
  end
  
  def res
    @resource_details
  end
  
# private

  def test_build_url_for
    build = lambda { |*args| @collection.ieval { build_url_for(*args) } }
    
    def res.site; WebService::Site.new("http://example.com") end
    def res.singleton; false end
    def res.element_name; "foo" end
    
    # Collection
    assert_equal "/foos", build[nil, nil].path
    
    # Member
    assert_equal "/foos/1", build[1, nil].path
    
    # Member action
    assert_equal "/foos/1/action", build[1, :action].path
    
    # Singleton
    def res.singleton; true end
    assert_equal "/foo", build[nil, nil].path
    
    # Non-singleton
    assert_raise ArgumentError, "singleton resources do not require an ID parameter" do
      build[1, nil]
    end
    def res.singleton; false end
    
    # Nested collection
    url = @collection.with_nesting([["bar", 1]]).ieval { build_url_for(nil, nil) }
    assert_equal "/bars/1/foos", url.path
    
    # Nested collection missing the ID for the association
    assert_raise RuntimeError, "attribute `bar_id' is missing" do
      @collection.with_nesting([["bar", nil]]).ieval { build_url_for(nil, nil) }
    end
  end

# private # utilities

  def test_recognize
    # Single pattern
    hash, string, symbol = @collection.instance_eval { recognize([Hash, /^a/, Symbol], "abc", {:options => true}) }
    assert_equal({:options => true}, hash)
    assert_equal("abc", string)
    assert_equal(nil, symbol)
    
    # Multiple patterns
    symbol, integer = @collection.instance_eval { recognize([Symbol, [/^\d+$/, Integer]], 3, :other) }
    assert_equal 3, integer
    assert_equal :other, symbol
    
    symbol, integer = @collection.instance_eval { recognize([Symbol, [/^\d+$/, Integer]], "3", :other) }
    assert_equal "3", integer
    assert_equal :other, symbol
  end
end
