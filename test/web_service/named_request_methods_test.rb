require "test_helper"

class WebService::NamedRequestMethodsTest < Test::Unit::TestCase
  def test_collection_actions
    expect_request Foo,
      :get, "/foos/bar",
      :return => {:status => "200", :body => "bar"}
    assert_equal "bar", Foo.get(:bar)
    
    expect_request Foo,
      :get, "/foos/bar?a=b",
      :return => {:status => "200", :body => "bar"}
    assert_equal "bar", Foo.get(:bar, :a => :b)
    
    expect_request Foo,
      :put, "/foos/bar",
      :return => {:status => "200", :body => "bar"}
    assert_equal "bar", Foo.put(:bar)
  end
  
  def test_member_actions
    foo = Foo.new("id" => 1)
    
    expect_request foo,
      :put, "/foos/1/bar",
      :return => {:status => "200", :body => "bar"}
    
    assert_equal "bar", foo.put(:bar)
  end
end
