module Loggun
  module Modifiers
    class Base
      class << self
        private :new

        def instance
          @instance ||= new
        end

        def use
          instance.apply
        end
      end

      def apply
        raise NotImplementedError, 'You must implement #apply in your modifier.'
      end
    end
  end
end