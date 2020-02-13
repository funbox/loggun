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
      data[:tags_text] = tags_text

      format(config.pattern + "\n", data)
    end

    def tagged(*tags)
      new_tags = push_tags(*tags)
      yield self
    ensure
      pop_tags(new_tags.size)
    end

    def push_tags(*tags)
      tags.flatten.reject(&:blank?).tap do |new_tags|
        current_tags.concat new_tags
      end
    end

    def pop_tags(size = 1)
      current_tags.pop size
    end

    def clear_tags!
      current_tags.clear
    end

    def current_tags
      thread_key = @thread_key ||= "loggun_tagged_logging_tags:#{object_id}"
      Thread.current[thread_key] ||= []
    end

    def tags_text
      tags = current_tags
      if tags.one?
        "[#{tags[0]}] "
      elsif tags.any?
        tags.collect { |tag| "[#{tag}] " }.join
      end
    end

    private

    def config
      Loggun::Config.instance
    end
  end
end
