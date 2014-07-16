module YardTypes

  # A +TypeConstraint+ specifies the set of acceptable types
  # which can satisfy the constraint. Parsing any YARD type
  # description will return a +TypeConstraint+ instance.
  #
  # @see YardTypes.parse
  class TypeConstraint
    # @return [Array<Type>]
    attr_reader :accepted_types

    # @param types [Array<Type>] the list of acceptable types
    def initialize(types)
      @accepted_types = types
    end

    # @param i [Fixnum]
    # @return [Type] the type at index +i+
    # @todo deprecate this; remnant from original TDD'd API.
    def [](i)
      accepted_types[i]
    end

    # @return [Type] the first type
    # @todo deprecate this; remnant from original TDD'd API.
    def first
      self[0]
    end

    # @param obj [Object] Any object.
    # @return [Type, nil] The first type which matched +obj+,
    #   or +nil+ if none.
    def check(obj)
      accepted_types.find { |t| t.check(obj) }
    end

    # @return [String] A YARD type string describing this set of
    #   types.
    def to_s
      accepted_types.map(&:to_s).join(', ')
    end
  end

  # The base class for all supported types.
  class Type
    # @return [String]
    attr_accessor :name

    # @todo This interface was just hacked into place while
    #   enhancing the parser to return {DuckType}, {KindType}, etc.
    # @api private
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

    # @param name [String]
    def initialize(name)
      @name = name
    end

    # @return [String] returns the name.
    def to_s
      name
    end

    # @param obj [Object] Any object.
    # @return [Boolean] whether the object is of this type.
    # @raise [NotImplementedError] must be handled by the subclasses.
    def check(obj)
      raise NotImplementedError
    end
  end

  # A {DuckType} constraint is specified as +#some_message+,
  # and indicates that the object must respond to the method
  # +some_message+.
  class DuckType < Type
    # @return [String] The method the object must respond to;
    #   this does not include the leading +#+ character.
    attr_reader :message

    # @param name [String] The YARD identifier, eg +#some_message+.
    def initialize(name)
      @name    = name
      @message = name[1..-1]
    end

    # @param obj [Object] Any object.
    # @return [Boolean] +true+ if the object responds to +message+.
    def check(obj)
      obj.respond_to? message
    end
  end

  # A {KindType} constraint is specified as +SomeModule+ or
  # +SomeClass+, and indicates that the object must be a kind of that
  # module.
  class KindType < Type
    # Type checks a given object. Special consideration is given to
    # the pseudo-class +Boolean+, which does not actually exist in Ruby,
    # but is commonly used to mean +TrueClass, FalseClass+.
    #
    # @param obj [Object] Any object.
    # @return [Boolean] +true+ if +obj.kind_of?(constant)+.
    def check(obj)
      if name == 'Boolean'
        obj == true || obj == false
      else
        obj.kind_of? constant
      end
    end

    # @return [Module] the constant specified by +name+.
    # @raise [TypeError] if the constant is neither a module nor a class
    # @raise [NameError] if the specified constant could not be loaded.
    def constant
      @constant ||=
        begin
          const = name.split('::').reduce(Object) { |namespace, const|
            namespace.const_get(const)
          }

          unless const.kind_of?(Module)
            raise TypeError, "class or module required; #{name} is a #{const.class}"
          end

          const
        end
    end
  end

  # A {LiteralType} constraint is specified by the name of one of YARD's
  # supported "literals": +true+, +false+, +nil+, +void+, and +self+, and
  # indicates that the object must be exactly one of those values.
  #
  # However, +void+ and +self+ have no particular meaning: +void+ is typically
  # used solely to specify that a method returns no meaningful types; and
  # +self+ is used to specify that a method returns its receiver, generally
  # to indicate that calls can be chained. All values type check as valid
  # objects for +void+ and +self+ literals.
  class LiteralType < Type
    # @return [Array<String>] the list of supported literal identifiers.
    def self.names
      @literal_names ||= %w(true false nil void self)
    end

    # @param obj [Object] Any object.
    # @return [Boolean] +true+ if the object is exactly +true+, +false+, or
    #   +nil+ (depending on the value of +name+); for +void+ and +self+
    #   types, this method *always* returns +true+.
    # @raise [NotImplementedError] if an unsupported literal name is to be
    #   tested against.
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

  # A {CollectionType} is specified with the syntax +Kind<Some, #thing>+, and
  # indicates that the object is a kind of +Kind+, containing only objects which
  # type check against +Some+ or +#thing+.
  #
  # @todo The current implementation of type checking here requires that the collection
  #   respond to +all?+; this may not be ideal.
  class CollectionType < Type
    # @return [Array<Type>] the acceptable types for this collection's contents.
    attr_accessor :types

    # @param name [String] the name of the module the collection must be a kind of.
    # @param types [Array<Type>] the acceptable types for the collection's contents.
    def initialize(name, types)
      @name = name
      @types = types
    end

    # @return [String] a YARD type description representing this type.
    def to_s
      "%s<%s>" % [name, types.map(&:to_s).join(', ')]
    end

    # @param obj [Object] Any object.
    # @return [Boolean] +true+ if the object is both a kind of +name+, and all of
    #   its contents (if any) are of the types in +types+. Any combination, order,
    #   and count of content types is acceptable.
    def check(obj)
      return false unless KindType.new(name).check(obj)

      obj.all? do |el|
        # TODO -- could probably just use another TypeConstraint here
        types.any? { |type| type.check(el) }
      end
    end
  end

  # A {TupleType} is specified with the syntax +(Some, Types, #here)+, and indicates
  # that the contents of the collection must be exactly that size, and each element
  # must be of the exact type specified for that index.
  #
  # @todo The current implementation of type checking here requires that the collection
  #   respond to both +length+ and +[]+; this may not be ideal.
  class TupleType < CollectionType
    def initialize(name, types)
      @name  = name == '<generic-tuple>' ? nil : name
      @types = types
    end

    # @return [String] a YARD type description representing this type.
    def to_s
      "%s(%s)" % [name, types.map(&:to_s).join(', ')]
    end

    # @param obj [Object] Any object.
    # @return [Boolean] +true+ if the collection's +length+ is exactly the length of
    #   the expected +types+, and each element with the collection is of the type
    #   specified for that index by +types+.
    def check(obj)
      return false unless name.nil? || KindType.new(name).check(obj)
      return false unless obj.respond_to?(:length) && obj.respond_to?(:[])
      return false unless obj.length == types.length

      enum = types.to_enum
      enum.with_index.all? do |t, i|
        t.check(obj[i])
      end
    end
  end

  # A {HashType} is specified with the syntax +{KeyType =>
  # ValueType}+, and indicates that all keys in the hash must be of
  # type +KeyType+, and all values must be of type +ValueType+.
  #
  # An alternate syntax for {HashType} is also available as +Hash<A,
  # B>+, but its usage is not recommended; it is less capable than the
  # +{A => B}+ syntax, as some inner type constraints can not be
  # parsed reliably.
  #
  # A {HashType} actually only requires that the object respond to
  # both +keys+ and +values+; it should be capable of type checking
  # any object which conforms to that interface.
  #
  # @todo Enforce kind, eg +HashWithIndifferentAccess{#to_sym => Array}+,
  #   in case you _really_ care that it's indifferent. Maybe?
  class HashType < Type
    # @return [Array<Type>] the set of acceptable types for keys
    attr_reader :key_types

    # @return [Array<Type>] the set of acceptable types for values
    attr_reader :value_types

    # @param name [String] the kind of the expected object; currently unused.
    # @param key_types [Array<Type>] the set of acceptable types for keys
    # @param value_types [Array<Type>] the set of acceptable types for values
    def initialize(name, key_types, value_types)
      @name = name
      @key_types = key_types
      @value_types = value_types
    end

    # Unlike the other types, {HashType} can result from two alternate syntaxes;
    # however, this method will *only* return the +{A => B}+ syntax.
    #
    # @return [String] A YARD type description representing this type.
    def to_s
      "{%s => %s}" % [
        key_types.map(&:to_s).join(', '),
        value_types.map(&:to_s).join(', ')
      ]
    end

    # @param obj [Object] Any object.
    # @return [Boolean] +true+ if the object responds to both +keys+ and +values+,
    #   and every key type checks against a type in +key_types, and every value
    #   type checks against a type in +value_types+.
    def check(obj)
      return false unless obj.respond_to?(:keys) && obj.respond_to?(:values)
      obj.keys.all? { |key| key_types.any? { |t| t.check(key) } } &&
        obj.values.all? { |value| value_types.any? { |t| t.check(value) } }
    end
  end

end
