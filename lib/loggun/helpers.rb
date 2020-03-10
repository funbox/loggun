module Loggun
  module Helpers
    def type
      Thread.current[:loggun_type]
    end

    def type=(type)
      Thread.current[:loggun_type] = normalize(type)
    end

    def with_type(type)
      previous_type = self.type
      self.type = type
      yield
    ensure
      self.type = previous_type
    end

    private

    def normalize(type)
      return unless type

      type = type.to_s.strip.tr(" \t\r\n", ' ').squeeze(' ')
      type.empty? ? nil : type
    end
  end
end