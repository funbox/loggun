require 'singleton'

module Loggun
  ## Class for configurations
  class Config
    include Singleton

    DEFAULTS = {
      pattern: '%{time} - %{pid} %{severity} %{type} %{tags_text}%{agent} %{message}',
      parent_transaction_to_message: true,
      precision: :milliseconds,
      controllers: %w[ApplicationController]
    }.freeze
    DEFAULT_MODIFIERS = %i[rails sidekiq clockwork incoming_http outgoing_http].freeze

    attr_accessor(
      :formatter,
      :pattern,
      :parent_transaction_to_message,
      :precision,
      :modifiers,
      :controllers,
      :custom_modifiers
    )

    def initialize
      @formatter = Loggun::Formatter.new
      @precision = DEFAULTS[:precision]
      @pattern = DEFAULTS[:pattern]
      @parent_transaction_to_message = DEFAULTS[:parent_transaction_to_message]
      @modifiers = Loggun::OrderedOptions.new
      @controllers = DEFAULTS[:controllers]
      @custom_modifiers = []
    end

    class << self
      def configure(&block)
        block.call(instance)
        use_modifiers
        instance
      end

      def use_modifiers
        DEFAULT_MODIFIERS.each do |modifier|
          next unless instance.modifiers.public_send(modifier)

          require_relative "modifiers/#{modifier}"
          klass = Loggun::Modifiers.const_get(modifier.to_s.camelize)
          klass.use
        end

        instance.custom_modifiers.each(&:use)
      end

      def setup_formatter(app)
        Loggun.application = app
        Loggun.application.logger.formatter = instance.formatter
      end
    end

    def add_modifier(modifier)
      return unless modifier.respond_to? :use

      custom_modifiers << modifier
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
  end
end
