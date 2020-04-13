module Loggun
  module Modifiers
    class Sidekiq
      class LoggunFormatter < ::Sidekiq::Logger::Formatters::Base
        def call(severity, time, _program_name, message)
          message, loggun_type = prepared_message(message)
          Loggun::Formatter.new.call(severity, time.utc, nil, message, loggun_type: loggun_type)
        end

        def prepared_message(message)
          if %w[start done fail].include?(message)
            loggun_type = "sidekiq.job.#{message}"
            message = "#{::Sidekiq.dump_json(ctx)}"
          else
            loggun_type = 'app.sidekiq.control'
            message = { tid: tid, message: message }
            message.merge!(context: format_context) if format_context
          end

          [message, loggun_type]
        end
      end
    end
  end
end
