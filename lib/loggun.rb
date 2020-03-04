require 'loggun/version'
require 'loggun/ordered_options'
require 'loggun/formatter'
require 'loggun/config'
require 'loggun/modifiers'
require 'loggun/helpers'

module Loggun
  class Error < StandardError; end

  class << self
    include Loggun::Helpers

    attr_accessor :application
  end
end
