Object.class_eval do
  undef :id if method_defined?(:id)
end

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

def URI(object)
  URI === object ? object : URI.parse(object.to_s)
end

URI.class_eval do
  def obfuscate
    returning(dup) do |obfuscated|
      obfuscated.user &&= '***'
      obfuscated.password &&= '***'
    end
  end
end

class << CGI
  alias_method :old_escape, :escape
  def escape(string)
    old_escape(string).gsub(/\./, '%' + '.'.unpack('H2')[0])
  end
end
