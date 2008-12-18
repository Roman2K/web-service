require "test_helper"

class WebService::CRUDOperationsTest < Test::Unit::TestCase
  def test_all
    will_return = expect_request_for_foos_index_with_param_bar_equals_baz
    foos = Foo.all(:bar => :baz)
    assert_equal will_return, foos
  end
  
  def test_cache
    collection = Foo.new('id' => 1).bars
    
    collection.cache = [{'id' => 1}, {'bar' => {'id' => 2}}, Bar.new('id' => 3)]
    expected = [Bar.new('id' => 1), Bar.new('id' => 2), Bar.new('id' => 3)]
    assert_equal expected, collection.all
    
    collection.flush_cache
    expect_request collection,
      :get, "/foos/1/bars", :return => {:status => "200", :body => []}
    assert_equal [], collection.all
  end
  
  def test_first
    will_return = expect_request_for_foos_index_with_param_bar_equals_baz
    assert_equal will_return.first, Foo.first(:bar => :baz)
  end
  
  def test_last
    will_return = expect_request_for_foos_index_with_param_bar_equals_baz
    assert_equal will_return.last, Foo.last(:bar => :baz)
  end
  
  def test_find
    expect_request Foo,
      :get, "/foos/1?bar=baz",
      :return => {:status => "200", :body => {"foo" => {"id" => 1}}}
    assert_equal Foo.new('id' => 1), Foo.find(1, :bar => :baz)
    
    expect_request Foo,
      :get, "/foos/1", :return => {:status => "404"}
    assert_raise WebService::ResourceNotFound do
      Foo.find(1)
    end
  end
  
  def test_build
    type_foo = Class.new(Foo)
    def type_foo.implicit_attributes; {:a => :b, :c => :d} end
    foo = type_foo.build("a" => :overridden, "e" => "f")
    assert_equal({"a" => :overridden, "c" => :d, "e" => "f"}, foo.attributes)
  end
  
private

  def expect_request_for_foos_index_with_param_bar_equals_baz
    expect_request Foo,
      :get, "/foos?bar=baz",
      :return => {:status => "200", :body => [{"foo" => {"id" => 1}}, {"foo" => {"id" => 2}}]}
    [Foo.new("id" => 1), Foo.new("id" => 2)]
  end
end
