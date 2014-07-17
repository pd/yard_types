require 'spec_helper'

module YardTypes
  describe DuckType do
    context '#description' do
      it "says the object should respond to its message" do
        type = DuckType.new('#msg')
        expect(type.description).to eq('an object that responds to #msg')
      end
    end
  end

  describe KindType do
    context '#description' do
      it "says the object should be a kind of its module" do
        type = KindType.new('Struct')
        expect(type.description).to eq('Struct')
      end
    end
  end

  describe LiteralType do
    context '#description' do
      LiteralType.names.each do |literal|
        specify literal do
          type = LiteralType.new(literal)
          expect(type.description).to eq(literal)
        end
      end
    end
  end

  describe CollectionType do
    context '#description' do
      let(:type) { CollectionType.new('Array', [KindType.new('Foo'), DuckType.new('#bar')]) }

      it "specifies its Kind" do
        expect(type.description).to match(/Array/)
      end

      it "specifies its inner content types" do
        expect(type.description).to match(/Foo, or an object that responds to #bar/)
      end
    end
  end

  describe TupleType do
    context '#description' do
      let(:type) { TupleType.new('Array', [LiteralType.new('false'), KindType.new('Set')]) }

      it 'specifies its Kind' do
        expect(type.description).to match(/Array/)
      end

      it 'specifies its contents, in order' do
        expect(type.description).to match(/\(false, Set\)/)
      end

      it 'omits its Kind if unspecified' do
        type = YardTypes.parse('(Set, Numeric)').accepted_types.first
        expect(type.description).to eql('a tuple containing (Set, Numeric)')
      end
    end
  end

  describe HashType do
    context '#description' do
      let(:type) { HashType.new('Hash', [DuckType.new('#to_s')], [KindType.new('Date'), KindType.new('DateTime')]) }

      it "specifies its Kind" do
        expect(type.description).to match(/Hash/)
      end

      it "specifies its key types" do
        expect(type.description).to match(/keys of \(an object that responds to #to_s\)/)
      end

      it "specifies its value types" do
        expect(type.description).to match(/values of \(Date, or DateTime\)/)
      end
    end
  end
end
