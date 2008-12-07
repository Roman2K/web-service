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
    class Associate < Struct.new(:id)
      def self.find
      end
      def initialize(attrs)
        self.id = attrs['id']
      end
    end
    class NotAssociate
    end
  }
  
  def test_association_querying
    res = Resource.new
    
    assert !res.respond_to?(:associate?)
    
    res.associate = Associate.new('id' => 1)
    assert res.associate?
    assert res.associate_id?
    
    res.associate = nil
    assert !res.associate?
    assert !res.associate_id?
  end
  
  def test_association_writers
    res = Resource.new
    
    res.associate = {"id" => 1}
    assert_equal Associate.new('id' => 1), res.associate
    assert_equal 1, res.associate_id
    
    res.associate = {"id" => 1}
    res.associate = nil
    assert_equal nil, res.associate
    assert_equal nil, res.associate_id
    
    res.associate = {"id" => 1}
    res.associate_id = nil
    assert_equal nil, res.associate
    assert_equal nil, res.associate_id
    
    res.associate = {"id" => 1}
    res.associate_id = 1
    Associate.stubs(:find).with(1).returns("reset").once
    assert_equal "reset", res.associate
    assert_equal 1, res.associate_id
    
    associate = Associate.new('id' => 2)
    res.associate = associate
    assert_equal associate.object_id, res.associate.object_id
    assert_equal 2, res.associate_id
    
    res.associate = nil
    assert_raise WebService::ResourceNotSaved do
      res.associate = Associate.new('id' => nil)
    end
    assert_equal nil, res.associate
    
    res.associate = Associate.new('id' => 2)
    res.associate_id = 3
    Associate.expects(:find).with(3).returns("fetched").once
    assert_equal "fetched", res.associate
    assert_equal "fetched", res.associate
    
    res.not_associate = {"id" => 4}
    assert_equal({"id" => 4}, res.not_associate)
    
    res.noclass_id = 5
    assert_raise NameError, "uninitialized constant Noclass" do
      res.noclass
    end
    
    res.not_associate_id = 6
    expected_message = "class NotAssociate found for association `not_associate' is not a resource class"
    assert_raise WebService::NotResourceClass, expected_message do
      res.not_associate
    end
  end
end
