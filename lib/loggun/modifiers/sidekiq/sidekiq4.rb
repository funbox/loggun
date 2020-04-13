module Loggun
  module Modifiers
    class Sidekiq
      class LoggunFormatter < ::Sidekiq::Logging::Pretty
        def call(severity, time, _program_name, message)
          message, loggun_type = prepared_message(message)
          Loggun::Formatter.new.call(severity, time.utc, nil, message, loggun_type: loggun_type)
        end

        def prepared_message(message)
          if %w[start].include?(message) || message[/^(done|fail):\s(.*)\ssec$/]
            message, elapsed = split_msg_and_time(message)
            loggun_type = "sidekiq.job.#{message}"
            message = { tid: "#{Thread.current.object_id.to_s(36)}", context: context.strip }
            message[:elapsed] = elapsed if elapsed
          else
            loggun_type = 'app.sidekiq.control'
            message = { tid: Thread.current.object_id.to_s(36), message: message }
            message.merge!(context: context) if context
          end

          [message, loggun_type]
        end

        def split_msg_and_time(message)
          unless message[/^done:\s(.*)\ssec$/] || message[/^fail:\s(.*)\ssec$/]
            return [message, nil]
          end

          msg_type = message[/^done:\s(.*)\ssec$/] ? 'done' : 'fail'

          msg = message[/#{msg_type}:\s(.*)\ssec/] ? msg_type : message
          elapsed = message.gsub(/#{msg_type}:\s/, '').gsub('sec', '').strip
          [msg, elapsed]
        end
      end
    end
  end
end