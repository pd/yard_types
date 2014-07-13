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

  # @return [Result]
  def validate(type, obj)
    constraint = parse(type)
    if constraint.check(obj)
      Success.new
    else
      Failure.new
    end
  end

  def parse(type)
    Parser.parse(type)
  end
end
