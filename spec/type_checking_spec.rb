require 'spec_helper'
require 'set'

describe YardTypes, 'type checking' do
  matcher :type_check do |obj|
    match do |type|
      result = YardTypes.check(type, obj)
      result.success?
    end

    description do |type|
      "type checks against #{type.inspect}"
    end

    failure_message do |type|
      "expected `#{obj.inspect}` to type check against #{type.inspect}"
    end

    failure_message_when_negated do |type|
      "expected `#{obj.inspect}` not to type check against #{type.inspect}"
    end
  end

  context 'ducks' do
    specify 'responds' do
      expect('#to_s').to    type_check(nil)
      expect('#reverse').to type_check('foo')
      expect('#name').to    type_check(Class)
    end

    specify 'does not respond' do
      expect('#bogus').not_to type_check(nil)
    end
  end

  context 'kinds' do
    specify 'is kind_of' do
      expect('String').to type_check('')
      expect('Object').to type_check([])
    end

    specify 'is not kind_of' do
      expect('String').not_to type_check([])
    end

    specify 'Boolean == true || false' do
      expect('Boolean').to     type_check(true)
      expect('Boolean').to     type_check(false)
      expect('Boolean').not_to type_check(nil)
    end

    specify 'constant resolution' do
      expect('YardTypes::DuckType').to type_check(YardTypes::DuckType.new('#foo'))
    end

    specify 'unknown constant' do
      expect {
        type = YardTypes.parse('ReversedString')[0] # mind the typo
        type.check('gnirts')
      }.to raise_error(NameError)
    end
  end

  context 'arrays' do
    specify 'inner type' do
      # Empty always passes
      expect('Array<String>').to type_check([])

      # Every element passes
      expect('Array<#reverse>').to type_check(['foo', 'bar'])
      expect('Array<#reverse>').to type_check([['a'], 'foo'])

      # Every element fails
      expect('Array<#reverse>').not_to type_check([1])

      # Some element fails
      expect('Array<#reverse>').not_to type_check(['foo', 1])
    end
  end

  context 'alternate collection types' do
    specify 'Set<Symbol>' do
      array = [:foo, :bar]
      set   = Set.new(array)

      expect('Set<Symbol>').to     type_check(set)
      expect('Set<Symbol>').not_to type_check(array)
    end
  end

  context 'tuples' do
    class ::MyTuple < Array
    end

    let(:type) { '(String, Fixnum, #reverse)' }

    specify 'matches' do
      expect(type).to type_check(['foo', 1,   []])
    end

    specify 'one type is wrong' do
      expect(type).not_to type_check([:nope, 1,   []])
      expect(type).not_to type_check(['foo', 1.0, []])
      expect(type).not_to type_check(['foo', 1,   nil])
    end

    specify 'invalid length' do
      expect(type).not_to type_check([])
      expect(type).not_to type_check(['foo'])
      expect(type).not_to type_check(['foo', 1])
      expect(type).not_to type_check(['foo', 1, [], true])
    end

    specify 'unspecified kind accepts any kind' do
      tuple = MyTuple.new
      tuple[0] = 'hi'
      tuple[1] = 1
      tuple[2] = []

      expect(type).to type_check(tuple)
    end

    context 'specified kind' do
      let(:type) { 'MyTuple(String, Fixnum)' }

      specify 'kind + contents match' do
        tuple = MyTuple.new
        tuple[0] = 'hi'
        tuple[1] = 1

        expect(type).to type_check(tuple)
      end

      specify 'kind matches, contents do not' do
        expect(type).not_to type_check(MyTuple.new)
      end

      specify 'contents match, but kind does not' do
        expect(type).not_to type_check(['hi', 1])
      end
    end
  end

  context 'hash' do
    context 'Hash<> syntax' do
      let(:type) { 'Hash<Fixnum, String>' }

      specify 'matches' do
        expect(type).to type_check({ 1 => 'foo', 2 => 'bar' })
      end

      specify 'wrong key type' do
        expect(type).not_to type_check({ 1.0 => 'foo' })
        expect(type).not_to type_check({ 1 => 'foo', :wrong => 'bar' })
      end

      specify 'wrong value type' do
        expect(type).not_to type_check({ 1 => :foo })
        expect(type).not_to type_check({ 1 => 'foo', 2 => :bar })
      end

      specify 'quacks like a hash' do
        map_type = Struct.new(:keys, :values)
        hash_map = map_type.new([1, 2], ['three', 'four'])
        expect(type).to type_check(hash_map)
      end
    end

    context 'Hash{} syntax' do
      let(:type) { '{Boolean => #reverse}' }

      specify 'matches' do
        expect(type).to type_check(false => [])
        expect(type).to type_check(true  => 'foo', false => [])
      end

      specify 'wrong key type' do
        expect(type).not_to type_check(:false => [])
        expect(type).not_to type_check(false => [], 'true' => 'bar')
      end

      specify 'wrong value type' do
        expect(type).not_to type_check(true => :fail)
        expect(type).not_to type_check(true => 'pass', false => :fail)
      end

      specify 'quacks like a hash' do
        map_type = Struct.new(:keys, :values)
        hash_map = map_type.new([true, false], ['three', [:four]])
        expect(type).to type_check(hash_map)
      end
    end
  end

  context 'literals' do
    specify 'nil' do
      expect('nil').to     type_check(nil)
      expect('nil').not_to type_check(false)
    end

    specify 'true' do
      expect('true').to     type_check(true)
      expect('true').not_to type_check(false)
      expect('true').not_to type_check(nil)
    end

    specify 'false' do
      expect('false').to     type_check(false)
      expect('false').not_to type_check(true)
      expect('false').not_to type_check(nil)
    end

    specify 'void' do
      expect('void').to type_check(nil)
      expect('void').to type_check('')
      expect('void').to type_check(['anything', :really])
    end

    specify 'self' do
      expect('self').to type_check(nil)
      expect('self').to type_check('')
      expect('self').to type_check(['anything', :really])
    end
  end

  context 'multiple acceptable types' do
    specify 'String, Symbol' do
      expect('String, Symbol').to     type_check('foo')
      expect('String, Symbol').to     type_check(:foo)
      expect('String, Symbol').not_to type_check([])
      expect('String, Symbol').not_to type_check(['foo', :foo])
    end

    specify 'Array<A, B>' do
      expect('Array<Fixnum, #to_i>').to type_check([])
      expect('Array<Fixnum, #to_i>').to type_check([1])
      expect('Array<Fixnum, #to_i>').to type_check(['1'])
      expect('Array<Fixnum, #to_i>').to type_check([nil])

      expect('Array<Fixnum, #to_i>').not_to type_check([:oops])
      expect('Array<Fixnum, #to_i>').not_to type_check(nil)
    end
  end

end
