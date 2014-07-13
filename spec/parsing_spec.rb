require 'spec_helper'

describe YardTypes, 'parsing' do
  def parse(type_string)
    YardTypes.parse(type_string)
  end

  matcher :be_type_class do |type|
    def type_class(type_identifier)
      YardTypes.const_get("#{type_identifier.to_s.capitalize}Type")
    end

    match do |type_string|
      result = YardTypes.parse(type_string)
      result.first.instance_of? type_class(type)
    end

    description do |type_string|
      "'#{type_string}' parses into a #{type_class(type).name} instance"
    end

    failure_message do |type_string|
      "expected '#{type_string}' to parse into a #{type_class(type).name} instance"
    end

    failure_message_when_negated do |type_string|
      "expected '#{type_string}' not to parse into a #{type_class(type).name} instance, but did"
    end
  end

  matcher :have_inner_types do |*expected_inner_types|
    def collection?(type)
      type.respond_to?(:types)
    end

    def matching_count?(actual, expected)
      actual.size == expected.size
    end

    def matching_type_classes?(actual, expected)
      actual.zip(expected).all? do |type, (klass_name, type_name)|
        klass = YardTypes.const_get("#{klass_name.to_s.capitalize}Type")
        type.is_a?(klass) && type.name == type_name
      end
    end

    match do |type_string|
      type = YardTypes.parse(type_string).first
      collection?(type) &&
        matching_count?(type.types, expected_inner_types) &&
        matching_type_classes?(type.types, expected_inner_types)
    end
  end

  specify 'literals' do
    expect('true').to  be_type_class(:literal)
    expect('false').to be_type_class(:literal)
    expect('nil').to   be_type_class(:literal)
    expect('void').to  be_type_class(:literal)
    expect('self').to  be_type_class(:literal)
  end

  specify 'duck' do
    expect('#foo').to be_type_class(:duck)
  end

  specify 'kind' do
    expect('Foo').to   be_type_class(:kind)
    expect('Array').to be_type_class(:kind)
    expect('Hash').to  be_type_class(:kind)
  end

  context 'parameterized array' do
    specify 'not bare `Array` type' do
      expect('Array').not_to be_type_class(:collection)
    end

    specify 'Array<...>' do
      expect('Array<String>').to be_type_class(:collection)
      expect('Array<#foo>').to   be_type_class(:collection)
      expect('Array<#a, #b>').to be_type_class(:collection)
    end

    specify 'inner types' do
      expect('Array<String>').to have_inner_types([:kind, 'String'])

      expect('Array<String, #to_date>').to have_inner_types([:kind, 'String'],
                                                            [:duck, '#to_date'])
    end
  end

  context 'tuples' do
    specify '(...)' do
      expect('(String)').to be_type_class(:tuple)
      expect('(String, #to_date, true)').to be_type_class(:tuple)
    end

    specify 'inner types' do
      expect('(String)').to have_inner_types([:kind, 'String'])

      expect('(String, #to_date, true)').to have_inner_types([:kind, 'String'],
                                                             [:duck, '#to_date'],
                                                             [:literal, 'true'])
    end
  end

  context 'hashes' do
    specify 'Hash<a, b>' do
      expect('Hash<#a, #b>').to be_type_class(:hash)
      expect('Hash<Fixnum, String>').to be_type_class(:hash)
      expect('Hash<(#some, #tuple), Array<#to_date>>').to be_type_class(:hash)
    end

    specify 'Hash<a> | Hash<a, b, c> => SyntaxError' do
      expect { parse('Hash<a>') }.to raise_error(SyntaxError)
      expect { parse('Hash<a, b, c>') }.to raise_error(SyntaxError)
    end

    specify '{a => b}' do
      expect('{A => B}').to be_type_class(:hash)
      expect('{#a, #b => #to_date}').to be_type_class(:hash)
    end
  end
end

describe YardTypes::Type, '#to_s' do
  [
    # Kind
    'String', 'Boolean', 'Array', 'String, Symbol',

    # Duck
    '#foo', '#foo, #bar',

    # Literals
    'true', 'false', 'self', 'nil', 'void', 'true, false, nil',

    # Collection
    'Array<Fixnum>', 'Array<Fixnum, (#to_i, #to_f)>', 'Set<Date>',

    # Tuple
    '(String, Boolean)', '(A, B), (C, D)',

    # Hash
    '{String => Symbol}', '{#a, #b => (A, B)}', '{#foo => #bar}, {Fixnum => String}',

    # Crazy
    '(Array<(#foo, #bar), {String => Symbol}>, #to_sym, (nil, Boolean))'
  ].each do |string|

    specify string do
      parsed = YardTypes.parse(string)
      expect(parsed.to_s).to eq(string)
    end

  end

  it "does not preserve Hash<> notation" do
    parsed = YardTypes.parse('Hash<(#a, #b), Symbol>')
    expect(parsed.to_s).to eq('{(#a, #b) => Symbol}')
  end
end
