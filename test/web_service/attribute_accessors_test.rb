require 'test_helper'

class WebService::AttributeAccessorsTest < Test::Unit::TestCase
  class Resource
    include WebService::AttributeAccessors
  end
  
  def setup
    @res = Resource.new(:foo => :bar, :baz => nil, :void => " ")
  end
  
  def test_attributes
    res = Resource.new(:foo => :bar, "baz" => :foo)
    
    assert_equal({"foo" => :bar, "baz" => :foo}, res.attributes)
    
    hash = res.attributes
    hash[:hijack] = :value
    assert !res.respond_to?(:hijack)
  end
  
  def test_attributes=
    res = Resource.new(:foo => :bar)
    
    res.attributes = {:bar => :foo}
    
    assert !res.respond_to?(:foo)
    assert_equal :foo, res.bar
  end
  
  def test_methods
    res = Resource.new(:foo => :bar)
    
    if RUBY_VERSION < '1.9'
      assert_equal ["foo", "foo=", "foo?"], res.methods - Resource.instance_methods
    else
      assert_equal [:foo, :foo=, :foo?], res.methods - Resource.instance_methods
    end
  end
  
  def test_respond_to
    res = Resource.new(:foo => :bar)
    
    # Still responds to regular methods
    assert_respond_to(res, :object_id)

    # Respond to attribute accessor methods
    assert_respond_to(res, :foo)
    assert_respond_to(res, :foo=)
    assert_respond_to(res, :foo?)
    
    # Doesn't respond to other methods
    assert !res.respond_to?(:bar)
  end
  
  def test_querying
    assert @res.foo?    # present
    assert !@res.baz?   # blank
    assert !@res.void?  # blank
    
    # wrong number of arguments
    assert_raise ArgumentError do
      @res.foo?(:extra)
    end
    
    # inexistent
    assert_raise NoMethodError do
      @res.bar?
    end
  end
  
  def test_readers
    assert_equal :bar, @res.foo
    assert_equal nil,  @res.baz
    assert_raise NoMethodError do
      @res.unknown_attribute
    end
    
    # wrong number of arguments
    assert_raise ArgumentError do
      @res.foo("a")
    end
  end
  
  def test_writers
    res = Resource.new
    
    # first value
    res.foo = :bar
    assert_equal :bar, res.foo
    
    # second value
    res.foo = :foo
    assert_equal :foo, res.foo
    
    # wrong number of arguments
    assert_raise ArgumentError do
      res.send(:foo=, "a", "b")
    end
  end
  
  ##########################
  #  Association accessors
  ##########################

  Object.class_eval %q{
    class NotResource
    end
  }
  
  def test_association_querying
    bar = Bar.new
    
    assert !bar.respond_to?(:foo?)
    
    bar.foo = Foo.new('id' => 1)
    assert bar.foo?
    assert bar.foo_id?
    
    bar.foo = nil
    assert !bar.foo?
    assert !bar.foo_id?
  end
  
  def test_association_writers
    bar = Resource.new
    
    bar.foo = {"id" => 1}
    assert_equal Foo.new('id' => 1), bar.foo
    assert_equal 1, bar.foo_id
    
    bar.foo = {"foo" => {"id" => 1}}
    assert_equal Foo.new('id' => 1), bar.foo
    assert_equal 1, bar.foo_id
    
    bar.foo = {"id" => 1}
    bar.foo = nil
    assert_equal nil, bar.foo
    assert_equal nil, bar.foo_id
    
    bar.foo = {"id" => 1}
    bar.foo_id = nil
    assert_equal nil, bar.foo
    assert_equal nil, bar.foo_id
    
    bar.foo = {"id" => 1}
    bar.foo_id = 1
    Foo.stubs(:find).with(1).returns("reset").once
    assert_equal "reset", bar.foo
    assert_equal 1, bar.foo_id
    
    foo = Foo.new('id' => 2)
    bar.foo = foo
    assert_equal foo.object_id, bar.foo.object_id
    assert_equal 2, bar.foo_id
    
    bar.foo = nil
    assert_raise WebService::ResourceNotSaved do
      bar.foo = Foo.new('id' => nil)
    end
    assert_equal nil, bar.foo
    
    bar.foo = Foo.new('id' => 2)
    bar.foo_id = 3
    Foo.expects(:find).with(3).returns("fetched").once
    assert_equal "fetched", bar.foo
    assert_equal "fetched", bar.foo
    
    bar.not_resource = {"id" => 4}
    assert_equal({"id" => 4}, bar.not_resource)
    
    bar.noclass_id = 5
    assert_raise NameError, "uninitialized constant Noclass" do
      bar.noclass
    end
    
    bar.not_resource_id = 6
    expected_message = "class NotResource found for association `not_resource' is not a resource class"
    assert_raise WebService::NotResourceClass, expected_message do
      bar.not_resource
    end
    
    not_resource = NotResource.new
    bar.attributes = {:not_resource => not_resource}
    assert_equal not_resource, bar.not_resource
  end
end
