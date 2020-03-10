require_relative 'modifiers/rails' if defined?(Rails)

module Loggun
  module Modifiers
    MODIFIERS = %i[rails].freeze
  end
end