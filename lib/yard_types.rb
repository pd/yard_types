require "yard_types/version"
require "yard_types/types"
require "yard_types/parser"

# {YardTypes} provides a parser for YARD type descriptions, and
# testing whether objects are of the specified types.
module YardTypes
  extend self

  # @abstract Base class for {Success} and {Failure}
  class Result
    def initialize(pass = false)
      @pass = pass
    end

    def success?
      @pass == true
    end
  end

  # Returned from {YardTypes.check} when a type check succeeds,
  # providing the particular type which satisfied the
  # {TypeConstraint}.
  class Success < Result
    def initialize
      super(true)
    end
  end

  # Returned from {YardTypes.check} when a type check fails,
  # providing a reference to the {TypeConstraint} and a means of
  # generating error messages describing the error.
  class Failure < Result
    def initialize
      super(false)
    end
  end

  # Parse a type string using the {Parser}, and return a
  # {TypeConstraint} instance representing the described
  # type.
  #
  # @param type [String, Array<String>] The YARD type description
  # @return [TypeConstraint]
  # @raise [SyntaxError] if the string could not be parsed
  # @example
  #   type = YardTypes.parse('MyClass, #quacks_like_my_class')
  #   type.check(some_object)
  def parse(type)
    type = type.join(', ') if type.respond_to?(:join)
    Parser.parse(type)
  end

  # Parses a type identifier with {#parse}, then validates that the
  # given +obj+ satisfies the type constraint.
  #
  # @param type [String, Array<String>] A YARD type description; see {#parse}.
  # @param obj [Object] Any object.
  # @return [Result] success or failure.
  def check(type, obj)
    constraint = parse(type)
    if constraint.check(obj)
      Success.new
    else
      Failure.new
    end
  end
end
