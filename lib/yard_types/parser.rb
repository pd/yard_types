require "yard_types/types"

module YardTypes

  # Initial code taken from https://github.com/lsegal/yard-types-parser --
  # unfortunately that was never released as a gem; and the code on master
  # doesn't actually run.
  class Parser
    TOKENS = {
      collection_start: /</,
      collection_end: />/,
      tuple_start: /\(/,
      tuple_end: /\)/,
      type_name: /#\w+|((::)?\w+)+/,
      type_next: /[,;]/,
      whitespace: /\s+/,
      hash_start: /\{/,
      hash_next: /=>/,
      hash_end: /\}/,
      parse_end: nil
    }

    def self.parse(string)
      TypeConstraint.new(new(string).parse)
    end

    def initialize(string)
      @scanner = StringScanner.new(string)
    end

    def parse
      types = []
      type = nil
      name = nil

      loop do
        found = false
        TOKENS.each do |token_type, match|
          if (match.nil? && @scanner.eos?) || (match && token = @scanner.scan(match))
            found = true
            case token_type
            when :type_name
              raise SyntaxError, "expecting END, got name '#{token}'" if name
              name = token

            when :type_next
              raise SyntaxError, "expecting name, got '#{token}' at #{@scanner.pos}" if name.nil?
              unless type
                type = Type.for(name)
              end
              types << type
              type = nil
              name = nil

            when :tuple_start, :collection_start
              name ||= "Array"
              type =
                if name == 'Hash' && token_type == :collection_start
                  contents = parse
                  if contents.length != 2
                    raise SyntaxError, "expected 2 types for key/value; got #{contents.length}"
                  end

                  HashType.new(name, [contents[0]], [contents[1]])
                elsif token_type == :collection_start
                  CollectionType.new(name, parse)
                else
                  TupleType.new(name, parse)
                end

            when :hash_start
              name ||= "Hash"
              type = HashType.new(name, parse, parse)

            when :hash_next, :hash_end, :tuple_end, :collection_end, :parse_end
              raise SyntaxError, "expecting name, got '#{token}'" if name.nil?
              unless type
                type = Type.for(name)
              end
              types << type
              return types
            end
          end

        end
        raise SyntaxError, "invalid character at #{@scanner.peek(1)}" unless found
      end
    end
  end

end
