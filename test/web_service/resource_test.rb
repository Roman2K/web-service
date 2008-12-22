require 'test_helper'

class WebService::ResourceTest < Test::Unit::TestCase
  @@anonymous = Class.new(WebService::Resource)
  @@anonymous_with_named_parent = Class.new(Foo)
  
# class

  def test_element_name
    # Anonymous class
    assert_raise NameError do
      @@anonymous.instance_eval { element_name }
    end

    # Named class
    assert_equal "foo", Foo.instance_eval { element_name }

    # Anonymous class with named parent
    assert_equal "foo", @@anonymous_with_named_parent.instance_eval { element_name }

    # Anonymous class with explicit element name
    anonymous = Class.new(WebService::Resource)
    anonymous.element_name = "bar"
    assert_equal "bar", anonymous.element_name
  end
  
  def test_belongs_to
    # Saving
    bar = Bar.new("foo" => Foo.new("id" => 1), "a" => "b")
    
    expect_request bar,
      :post, "/foos/1/bars", :body => {"bar" => {"foo_id" => 1, "a" => "b"}},
      :return => {:status => "201", :body => {"bar" => {"c" => "d"}}}
    
    bar.save
    assert_equal({"c" => "d"}, bar.attributes)
    
    # Fetching
    expect_request Bar, :get, "/bars", :return => {:status => "200", :body => []}
    Bar.all
  end
  
  def test_has_many
    foo = Foo.new("id" => 1)
    
    # Instantiation
    bar = foo.bars.build("a" => "b")
    assert_equal({"foo_id" => 1, "a" => "b"}, bar.attributes)
    
    # Fetching
    expect_request foo.bars,
      :get, "/foos/1/bars",
      :return => {:status => "200", :body => []}
    foo.bars.all
    
    # Creation
    expect_request foo.bars,
      :post, "/foos/1/bars", :body => {"bar" => {"foo_id" => 1, "a" => "b"}},
      :return => {:status => "201", :body => {"bar" => {"c" => "d"}}}
    foo.bars.create("a" => "b")
    
    # Arbitrary actions
    expect_request foo.bars,
      :delete, "/foos/1/bars/99",
      :return => {:status => "200"}
    foo.bars.delete(99)
  end
  
  def test_has_many=
    foo = Foo.new("id" => 1)
    foo.bars.expects(:cache=).with("collection")
    foo.bars = "collection"
  end
  
  def test_has_one
    foo = Foo.new("id" => 1)
    expect_request foo.instance_eval { association_collection_from_name(:bar) },
      :get, "/foos/1/bars",
      :return => {:status => "200", :body => {"bar" => {"a" => "b"}}}
    assert_equal Bar.new("a" => "b"), foo.bar
  end
  
# public
  
  def test_to_hash
    res = WebService::Resource.new(:foo => :bar)
    assert_equal res.attributes, res.to_hash
  end
  
  def test_to_s
    assert_equal "Foo(new)",  Foo.new.to_s
    assert_equal "Foo[1]",    Foo.new('id' => 1).to_s
  end
  
  def test_inspect
    assert_equal "#<Foo(new)>", Foo.new.inspect
    assert_equal "#<Foo[1]>",   Foo.new('id' => 1).inspect
    assert_equal "#<Foo[1] bar=2.0 baz=\"abcdefghijklmnopqrstuv...\">", Foo.new('id' => 1, 'bar' => 2.0, 'baz' => Array('a'..'z').join).inspect
    
    # with custom to_s
    foo = Foo.new
    def foo.to_s; "custom" end
    assert_equal "#<Foo(new)>", foo.inspect
  end
  
  def test_save
    #############
    #  Creation
    #############
    foo = Foo.new("a" => "b")
    
    expect_request foo,
      :post, "/foos", :body => {"foo" => {"a" => "b"}},
      :return => {:status => '201', :body => {"foo" => {"c" => "d"}}}
    
    foo.save
    assert_equal({"c" => "d"}, foo.attributes)
    
    # Accepted
    foo = Foo.new("a" => "b")
    expect_request foo,
      :post, "/foos", :body => {"foo" => {"a" => "b"}},
      :return => {:status => '202', :body => " "}
    foo.save
    assert_equal({"a" => "b"}, foo.attributes)
    
    ###########
    #  Update
    ###########
    foo = Foo.new("id" => 1, "a" => "b")
    
    expect_request foo,
      :put, "/foos/1", :body => {"foo" => {"id" => 1, "a" => "b"}},
      :return => {:status => "200", :body => {"foo" => {"c" => "d"}}}
    
    foo.save
    assert_equal({"c" => "d"}, foo.attributes)
    
    ##############
    #  Singleton
    ##############
    type_foo = Class.new(Foo) { self.singleton = true }
    
    # Creation
    foo = type_foo.new
    expect_request foo,
      :post, "/foo", :body => {"foo" => {}},
      :return => {:status => "201", :body => {"foo" => {}}}
    foo.save
    
    # Update
    foo = type_foo.new("id" => 1)
    expect_request foo,
      :put, "/foo", :body => {"foo" => {"id" => 1}},
      :return => {:status => "200", :body => {"foo" => {}}}
    foo.save
  end
end
