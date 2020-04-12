require 'singleton'

module Loggun
  ## Class for configurations
  class Config
    include Singleton

    DEFAULTS = {
      pattern: '%{time} - %{pid} %{severity} %{type} %{tags_text}%{agent} %{message}',
      parent_transaction_to_message: true,
      precision: :milliseconds,
      incoming_http: {
        controllers: %w[ApplicationController],
        success_condition: -> { response.code == '200' },
        error_info: -> { nil }
      }
    }.freeze
    DEFAULT_MODIFIERS = %i[rails sidekiq clockwork incoming_http outgoing_http].freeze

    attr_accessor(
      :formatter,
      :pattern,
      :parent_transaction_to_message,
      :precision,
      :modifiers,
      :custom_modifiers
    )

    def initialize
      @formatter = Loggun::Formatter.new
      @precision = DEFAULTS[:precision]
      @pattern = DEFAULTS[:pattern]
      @parent_transaction_to_message = DEFAULTS[:parent_transaction_to_message]
      @modifiers = Loggun::OrderedOptions.new
      @custom_modifiers = []
      set_default_modifiers
    end

    class << self
      def configure(&block)
        block.call(instance)
        use_modifiers
        instance
      end

      def use_modifiers
        DEFAULT_MODIFIERS.each do |modifier|
          next unless instance.modifiers.public_send(modifier)&.enable

          require_relative "modifiers/#{modifier}"
          klass = Loggun::Modifiers.const_get(modifier.to_s.camelize)
          klass.use
        end

        instance.custom_modifiers.each(&:use)
      end

      def setup_formatter(app, formatter = nil)
        Loggun.logger = app.logger
        Loggun.logger.formatter = formatter || instance.formatter
      end
    end

    def set_default_modifiers
      DEFAULT_MODIFIERS.each do |modifier|
        modifiers[modifier] = Loggun::OrderedOptions.new
        modifiers[modifier].enable = false
        next unless DEFAULTS[modifier].is_a?(Hash)

        modifiers[modifier].merge!(DEFAULTS[modifier])
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
