require 'simplecov'
SimpleCov.start do
  add_filter "/spec/"
end

require 'yard_types'
require 'pry'

RSpec.configure do |config|
  config.order = :rand
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
end
