module Loggun
  module Modifiers
    class ActiveRecord
      class LoggunLogSubscriber < ::ActiveRecord::LogSubscriber
        def sql(event)
          payload = event.payload
          return if IGNORE_PAYLOAD_NAMES.include?(payload[:name]) || payload[:cached]

          available_keys = ::Loggun::Config.instance.modifiers.active_record.payload_keys&.map { |k| k.downcase.to_sym }
          data = { sql: payload[:sql], name: payload[:name], duration: event.duration.round(4) }
          source = respond_to?(:extract_query_source_location) ? extract_query_source_location(caller) : nil
          data.merge!(source: source.gsub(/(?<=\.rb)(.*)$/, '')) if source
          if available_keys&.any?
            data.each { |k, _| data.delete(k) unless available_keys.include?(k) }
          end

          Loggun.info 'storage.sql.query', data
        end
      end
    end
  end
end