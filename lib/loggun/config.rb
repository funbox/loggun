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
    MODIFIERS = %i[rails sidekiq clockwork incoming_http outgoing_http].freeze

    attr_accessor(
      :formatter,
      :pattern,
      :parent_transaction_to_message,
      :precision,
      :modifiers,
      :controllers
    )

    def initialize
      @formatter = Loggun::Formatter.new
      @precision = DEFAULTS[:precision]
      @pattern = DEFAULTS[:pattern]
      @parent_transaction_to_message = DEFAULTS[:parent_transaction_to_message]
      @modifiers = Loggun::OrderedOptions.new
      @controllers = DEFAULTS[:controllers]
      set_modifiers
    end

    class << self
      def configure(&block)
        block.call(instance)
        use_modifiers
        instance
      end

      def use_modifiers
        MODIFIERS.each do |modifier|
          if instance.modifiers.public_send(modifier)
            require_relative "modifiers/#{modifier}"
          end
        end
      end

      def setup_formatter(app)
        Loggun.application = app
        Loggun.application.logger.formatter = instance.formatter
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
