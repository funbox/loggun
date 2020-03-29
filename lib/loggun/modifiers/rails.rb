module Loggun
  module Modifiers
    class Rails < Loggun::Modifiers::Base
      def apply
        require_relative 'rails/railtie' if defined?(::Rails)
      end
    end
  end
end
