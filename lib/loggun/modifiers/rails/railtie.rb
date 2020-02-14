require 'rails/railtie'

module Loggun
  module Modifiers
    module Rails
      class Railtie < ::Rails::Railtie
        config.after_initialize do |_app|
          Loggun::Config.setup_formatter(::Rails) if Loggun::Config.instance.modifiers.rails
        end
      end
    end
  end
end
