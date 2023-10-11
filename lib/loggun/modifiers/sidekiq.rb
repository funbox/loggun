require 'sidekiq' if defined?(::Sidekiq)

module Loggun
  module Modifiers
    class Sidekiq < Loggun::Modifiers::Base
      MIN_SIDEKIQ_V = '4.0.0'.freeze

      def apply
        return unless defined?(::Sidekiq) && ::Sidekiq::VERSION >= MIN_SIDEKIQ_V

        if ::Sidekiq::VERSION >= '7.0.0'
          ::Sidekiq.configure_client do |config|
            config.client_middleware do |chain|
              chain.add ClientMiddleware
            end
          end
        else
          ::Sidekiq.client_middleware do |chain|
            chain.add ClientMiddleware
          end
        end

        ::Sidekiq.configure_server do |config|
          Loggun::Config.setup_formatter(config, LoggunFormatter.new)
        end
      end

      if defined?(::Sidekiq)
        if ::Sidekiq::VERSION >= '6.0.0'
          require 'loggun/modifiers/sidekiq/sidekiq6'
        else
          require 'loggun/modifiers/sidekiq/sidekiq4'
        end
      end

      class ClientMiddleware
        def call(worker_class, _msg, queue, _redis_pool)
          yield.tap do |options|
            msg = "Job #{worker_class} JID-#{options['jid']} enqueued to `#{queue}`"
            Loggun.info('app.sidekiq.enqueued', msg, worker_class: worker_class, jid: options['jid'], queue: queue)
          end
        end
      end
    end
  end
end
