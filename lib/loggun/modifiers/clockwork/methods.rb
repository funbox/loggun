require 'clockwork'

module Clockwork
  module Methods
    def configure(&block)
      Clockwork.manager.configure_loggun(&block)
    end
  end
end