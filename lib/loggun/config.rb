require 'singleton'
require 'loggun/formatter'

module Loggun
  ## Class for configurations
  class Config
    include Singleton

    attr_reader :timestamp_precision
    attr_accessor(
      :formatter,
      :pattern
    )

    def initialize
      @formatter = Loggun::Formatter
      @timestamp_precision = precision_to_number(:milliseconds)
      @pattern =
        '%{time} - %{pid} %{severity} %{type} %{tags_text}%{agent} %{message}'
    end

    class << self
      def configure(&block)
        block.call(instance)
        instance
      end
    end

    def timestamp_precision=(precision)
      @timestamp_precision = precision_to_number(precision)
    end

    private

    def precision_to_number(value)
      case value
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
