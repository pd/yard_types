require "yard_types/version"
require "yard_types/types"
require "yard_types/parser"

module YardTypes
  extend self

  class Result
    def initialize(pass = false)
      @pass = pass
    end

    def success?
      @pass == true
    end
  end

  class Success < Result
    def initialize
      super(true)
    end
  end

  class Failure < Result
    def initialize
      super(false)
    end
  end

  # Parse a type string using the {Parser}, and return a
  # {TypeConstraint} instance representing the described
  # type.
  #
  # @param type [String] The YARD type description
  # @return [TypeConstraint]
  # @raise [SyntaxError] if the string could not be parsed
  # @example
  #   type = YardTypes.parse('MyClass, #quacks_like_my_class')
  #   type.check(some_object)
  def parse(type)
    Parser.parse(type)
  end

  # @return [Result]
  # @todo deprecate; rename it +check+ to match everything else.
  def validate(type, obj)
    constraint = parse(type)
    if constraint.check(obj)
      Success.new
    else
      Failure.new
    end
  end
end
