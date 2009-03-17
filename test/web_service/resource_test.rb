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
    
    expect_creation_on = lambda do |collection|
      expect_request collection,
        :post, "/foos/1/bars", :body => {"bar" => {"foo_id" => 1, "a" => "b"}},
        :return => {:status => "201", :body => {"bar" => {"c" => "d"}}}
    end
    
    # Instantiation
    bar = foo.bars.build("a" => "b")
    assert_equal({"foo_id" => 1, "a" => "b"}, bar.attributes)
    
    # Fetching
    expect_request foo.bars,
      :get, "/foos/1/bars",
      :return => {:status => "200", :body => []}
    foo.bars.all
    
    # Creation (bars.create)
    expect_creation_on[foo.bars]
    foo.bars.create("a" => "b")
    
    # Creation (bars.build.save)
    bar = foo.bars.build "a" => "b"
    expect_creation_on[bar]
    bar.save
    
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
    # Fetching
    foo = Foo.new("id" => 1)
    expect_request foo.instance_eval { association_collection_from_name(:bar, :singleton => true) },
      :get, "/foos/1/bar",
      :return => {:status => "200", :body => {"bar" => {"a" => "b"}}}
    assert_equal Bar.new("a" => "b"), foo.bar
    
    # Building + saving = creating
    foo = Foo.new("id" => 1)
    bar = foo.build_bar("a" => "b")
    expect_request bar,
      :post, "/foos/1/bar", :body => {"bar" => {"foo_id" => 1, "a" => "b"}},
      :return => {:status => "201", :body => {"bar" => {"c" => "d"}}}
    assert_equal Bar.new("c" => "d"), bar.save
    
    # Plural-form resource class name
    foo = Foo.new("id" => 1)
    expect_request foo.instance_eval { association_collection_from_name(:details, :singleton => true) },
      :get, "/foos/1/details",
      :return => {:status => "200", :body => {"details" => {"a" => "b"}}}
    assert_equal Details.new("a" => "b"), foo.details
    
    # Constant name resolution
    assert_raise NameError, /uninitialized constant Things\b/ do
      Class.new(Foo) { has_one :things }.new.things
    end
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
  
  def test_reload
    foo = Foo.new("id" => 1, "a" => "b")
    expect_request foo,
      :get, "/foos/1",
      :return => {:status => 200, :body => {"foo" => {"id" => 1, "b" => "c"}}}
    
    result = foo.reload
    
    assert_equal Foo.new("id" => 1, "b" => "c"), foo
    assert_equal foo.object_id, result.object_id
  end
end
