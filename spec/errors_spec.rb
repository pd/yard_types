require 'spec_helper'

describe 'Defensive error raising' do
  specify 'Type#check raises NotImplementedError' do
    type = YardTypes::Type.new('Foo')
    expect { type.check(nil) }.to raise_error(NotImplementedError)
  end

  specify 'LiteralType raises when checking for an unsupported literal' do
    type = YardTypes::LiteralType.new('zero')
    expect { type.check(0) }.to raise_error(NotImplementedError, /zero/)
  end
end
