require 'date'

module Loggun
  class Formatter
    DEFAULT_VALUE = '-'.freeze

    def call(severity, time, _program_name, message)
      data = Hash.new(DEFAULT_VALUE)
      data[:time] = time.iso8601(config.timestamp_precision)
      data[:pid] = Process.pid
      data[:message] = message.to_s.tr("\r\n", ' ').strip
      data[:severity] = severity&.present? ? severity.to_s : 'INFO'

      format(config.pattern + "\n", data)
    end

    private

    def config
      Loggun::Config.instance
    end
  end
end
