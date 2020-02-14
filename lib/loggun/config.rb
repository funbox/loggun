require 'singleton'

module Loggun
  ## Class for configurations
  class Config
    include Singleton

    DEFAULTS = {
      pattern: '%{time} - %{pid} %{severity} %{type} %{tags_text}%{agent} %{message}',
      precision: :milliseconds
    }.freeze
    MODIFIERS = %i[rails sidekiq].freeze

    attr_accessor(
      :formatter,
      :pattern,
      :precision,
      :modifiers
    )

    def initialize
      @formatter = Loggun::Formatter.new
      @precision = DEFAULTS[:precision]
      @pattern = DEFAULTS[:pattern]
      @modifiers = Loggun::OrderedOptions.new
      set_modifiers
    end

    class << self
      def configure(&block)
        block.call(instance)
        check_modifiers
        instance
      end

      def check_modifiers
        MODIFIERS.each do |modifier|
          if instance.modifiers.public_send(modifier)
            require_relative "modifiers/#{modifier}"
          end
        end
      end

      def setup_formatter(app)
        app.logger.formatter = instance.formatter
      end
    end

    def timestamp_precision
      case precision
      when :sec, :seconds then 0
      when :millis, :milliseconds, :ms then 3
      when :micros, :microseconds, :us then 6
      when :nanos, :nanoseconds, :ns then 9
      else
        3 # milliseconds
      end
    end

    private

    def set_modifiers
      MODIFIERS.each do |modifier|
        modifiers.send(modifier, false)
      end
    end
  end
end
