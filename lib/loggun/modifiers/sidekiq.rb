require 'sidekiq' if defined?(::Sidekiq)

module Loggun
  module Modifiers
    class Sidekiq < Loggun::Modifiers::Base
      MIN_SIDEKIQ_V = '4.0.0'.freeze

      def apply
        return unless defined?(::Sidekiq) && ::Sidekiq::VERSION >= MIN_SIDEKIQ_V

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
    end
  end
end
