require 'http'
require_relative 'block_logger'

module Loggun
  module Modifiers
    module OutgoingHttp
      module Http
        ::HTTP.default_options = {
          features: {
            logging: { logger: Loggun::Modifiers::OutgoingHttp::BlockLogger }
          }
        }
      end
    end
  end
end