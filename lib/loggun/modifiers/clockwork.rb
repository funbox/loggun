require_relative 'clockwork/manager'
require_relative 'clockwork/methods'

module Loggun
  module Modifiers
    module Clockwork
      ::Clockwork.configure {}
    end
  end
end
