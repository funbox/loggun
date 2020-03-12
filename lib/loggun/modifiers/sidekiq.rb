require 'sidekiq' if defined?(::Sidekiq)

module Loggun
  module Modifiers
    class Sidekiq < Loggun::Modifiers::Base
      def apply
        return unless defined?(::Sidekiq)

        ::Sidekiq.configure_server do |config|
          Loggun::Config.setup_formatter(config)
        end
      end
    end
  end
end
