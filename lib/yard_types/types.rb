module YardTypes

  class TypeConstraint
    attr_reader :accepted_types

    def initialize(types)
      @accepted_types = types
    end

    def [](i)
      accepted_types[i]
    end

    def first
      self[0]
    end

    def check(obj)
      accepted_types.any? { |t| t.check(obj) }
    end

    def to_s
      accepted_types.map(&:to_s).join(', ')
    end
  end

  class Type
    attr_accessor :name

    def self.for(name)
      case name
      when /^#/
        DuckType.new(name)
      when *LiteralType.names
        LiteralType.new(name)
      else
        KindType.new(name)
      end
    end

    def initialize(name)
      @name = name
    end

    def to_s
      name
    end

    def check(obj)
      raise NotImplementedError
    end
  end

  class DuckType < Type
    attr_reader :message

    def initialize(name)
      @name    = name
      @message = name[1..-1]
    end

    def check(obj)
      obj.respond_to? message
    end
  end

  class KindType < Type
    def check(obj)
      if name == 'Boolean'
        obj == true || obj == false
      else
        obj.kind_of? constant
      end
    end

    def constant
      Object.const_get(name)
    end
  end

  class LiteralType < Type
    def self.names
      @literal_names ||= %w(true false nil void self)
    end

    def check(obj)
      case name
      when 'true'         then obj == true
      when 'false'        then obj == false
      when 'nil'          then obj == nil
      when 'self', 'void' then true
      else raise NotImplementedError, "Unsupported literal type: #{name.inspect}"
      end
    end
  end

  class CollectionType < Type
    attr_accessor :types

    def initialize(name, types)
      @name = name
      @types = types
    end

    def to_s
      "%s<%s>" % [name, types.map(&:to_s).join(', ')]
    end

    def check(obj)
      # Collection kind
      return false unless KindType.new(name).check(obj)

      # Content types
      obj.all? do |el|
        types.any? { |type| type.check(el) }
      end
    end
  end

  class TupleType < CollectionType
    def to_s
      "(%s)" % [types.map(&:to_s).join(', ')]
    end

    def check(obj)
      return false unless obj.respond_to?(:length) && obj.respond_to?(:[])
      return false unless obj.length == types.length
      enum = types.to_enum
      enum.with_index.all? do |t, i|
        t.check(obj[i])
      end
    end
  end

  class HashType < Type
    attr_accessor :key_types, :value_types

    def initialize(name, key_types, value_types)
      @name = name
      @key_types = key_types
      @value_types = value_types
    end

    def to_s
      "{%s => %s}" % [
        key_types.map(&:to_s).join(', '),
        value_types.map(&:to_s).join(', ')
      ]
    end

    def check(obj)
      return false unless obj.respond_to?(:keys) && obj.respond_to?(:values)
      obj.keys.all? { |key| key_types.any? { |t| t.check(key) } } &&
        obj.values.all? { |value| value_types.any? { |t| t.check(value) } }
    end
  end

end
