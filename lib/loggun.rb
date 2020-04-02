require 'loggun/version'
require 'loggun/ordered_options'
require 'loggun/formatter'
require 'loggun/config'
require 'loggun/modifiers'
require 'loggun/modifiers/base'
require 'loggun/helpers'
require 'logger'

module Loggun
  class Error < StandardError; end

  class << self
    include Loggun::Helpers

    attr_writer :logger

    %i[unknown fatal error warn info debug].each do |method|
      alias_method method, "log_#{method}"
    end

    def logger
      @logger ||= default_logger
    end

    private

    def default_logger
      logger = Logger.new(STDOUT)
      logger.formatter = Config.instance.formatter
      logger
    end
  end
end
