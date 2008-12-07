require "test_helper"

class WebService::CrudOperationsTest < Test::Unit::TestCase
  def test_all
    expect_request Foo,
      :get, "/foos",
      :return => {:status => "200", :body => [{"foo" => {"id" => 1}}, {"foo" => {"id" => 2}}]}
    
    foos = Foo.all
    assert_equal [Foo.new("id" => 1), Foo.new("id" => 2)], foos
  end
  
  def test_build
    type_foo = Class.new(Foo)
    def type_foo.implicit_attributes; {:a => :b, :c => :d} end
    foo = type_foo.build("a" => :overridden, "e" => "f")
    assert_equal({"a" => :overridden, "c" => :d, "e" => "f"}, foo.attributes)
  end
end
