require 'singleton'
require 'loggun/formatter'

module Loggun
  ## Class for configurations
  class Config
    include Singleton

    DEFAULTS = {
      pattern: '%{time} - %{pid} %{severity} %{type} %{tags_text}%{agent} %{message}',
      precision: :milliseconds
    }.freeze

    attr_accessor(
      :formatter,
      :pattern,
      :precision,
      :modifiers,
      :enable_rails
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
        instance
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
      Loggun::Modifiers::MODIFIERS.each do |method|
        modifiers.send(method, false)
      end
    end
  end
end
