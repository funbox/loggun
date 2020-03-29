require 'rails/railtie'

module Loggun
  module Modifiers
    class Rails
      class Railtie < ::Rails::Railtie
        config.after_initialize do |_app|
          Loggun::Config.setup_formatter(::Rails)
        end
      end
    end
  end
end
