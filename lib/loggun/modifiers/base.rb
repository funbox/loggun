require 'singleton'

module Loggun
  module Modifiers
    class Base
      include Singleton

      class << self
        def use
          instance.apply
        end
      end

      def apply
        raise NotImplementedError, 'You must implement #apply in your modifier.'
      end

      def config
        Loggun::Config.instance
      end
    end
  end
end