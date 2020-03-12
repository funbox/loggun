require 'loggun/version'
require 'loggun/ordered_options'
require 'loggun/formatter'
require 'loggun/config'
require 'loggun/modifiers'
require 'loggun/modifiers/base'
require 'loggun/helpers'

module Loggun
  class Error < StandardError; end

  class << self

    include Loggun::Helpers

    attr_accessor :application

    %i[unknown fatal error warn info debug].each do |method|
      define_method(method) do |type, attrs = nil|
        next application.logger.send(method, type) unless attrs

        with_type(type) do
          application.logger.send(method, attrs)
        end
      end
    end
  end
end
