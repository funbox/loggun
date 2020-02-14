require 'sidekiq'

module Loggun
  module Modifiers
    module Sidekiq
      class ConfigureServer
        ::Sidekiq.configure_server do |config|
          Loggun::Config.setup_formatter(config) if Loggun::Config.instance.modifiers.sidekiq
        end
      end
    end
  end
end
