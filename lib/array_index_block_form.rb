Array.class_eval do
  alias_method :index_without_block_form, :index
  def index(*args, &block)
    if args.empty? && block
      each_with_index { |obj, idx| return idx if block.call(obj) }; nil
    elsif args.size == 1
      index_without_block_form(*args, &block)
    else
      raise ArgumentError, "wrong number of arguments (%d for 1)" % args.size
    end
  end
end if Array.instance_method(:index).arity == 1
