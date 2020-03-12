require 'http' if defined?(HTTP)
require_relative 'outgoing_http/block_logger'

module Loggun
  module Modifiers
    class OutgoingHttp < Loggun::Modifiers::Base
      def apply
        return unless defined?(HTTP)

        ::HTTP.default_options = {
          features: {
            logging: { logger: BlockLogger }
          }
        }
      end
    end
  end
end
