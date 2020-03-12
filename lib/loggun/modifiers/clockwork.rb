# frozen_string_literal: true

if defined?(::Clockwork)
  require_relative 'clockwork/manager'
  require_relative 'clockwork/methods'
end

module Loggun
  module Modifiers
    class Clockwork < Loggun::Modifiers::Base
      def apply
        return unless defined?(::Clockwork)

        ::Clockwork.configure {}
      end
    end
  end
end
