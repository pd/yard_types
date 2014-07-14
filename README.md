# yard_types

[![Build Status](https://travis-ci.org/pd/yard_types.svg?branch=master)](https://travis-ci.org/pd/yard_types)

Parse YARD type description strings -- eg `Array<#to_sym>` -- and use the
resulting types to check type correctness of objects at runtime.

## Installation
Like everything else these days:

~~~ruby
gem 'yard_types'
~~~

Note that the `yard` gem may automatically require anything named `yard_*` or
`yard-*` on your load path, and attempt to use it as a plugin. You could see
errors along the lines of `failed to load plugin yard_types`; this is harmless,
as best I can tell.

## Usage
Parse a type description string, and test an object against it:

~~~ruby
type = YardTypes.parse('#quack') #=> #<YardTypes::TypeConstraint ...>

type.check(Object.new)
#=> false

obj = Object.new
def obj.quack; 'quack!'; end
type.check(obj)
#=> true
~~~

## Caveats
YARD does not officially specify a syntax for its type descriptions; the syntax
used by its own documentation varies between files. The syntax supported in
this gem aims to follow the rules given by the [YARD Type Parser][type-parser].

In the wild, people seem to use a wide variety of different syntaxes, many of
which are unlikely to be supported right now. If you find any such examples,
feel free to file an issue -- or better yet, write a test, implement the feature,
and send me a pull request.

## Tests
Pretty standard. Just run `rake` or `rspec`.

## Contributing

1. Fork it ( http://github.com/pd/yard_types/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Credits
The bulk of the parser was [written by lsegal](lsegal-parser); unfortunately, it
was never released as a gem, and has sat untouched for 5 years. I've only modified
the parser to better support `Hash<A, B>` syntax and to use more consistent
naming patterns.

[type-parser]: http://yardoc.org/types
[lsegel-parser]: https://github.com/lsegal/yard-types-parser
