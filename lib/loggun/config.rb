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
      :precision
    )

    def initialize
      @formatter = Loggun::Formatter
      @precision = DEFAULTS[:precision]
      @pattern = DEFAULTS[:pattern]
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
  end
end
