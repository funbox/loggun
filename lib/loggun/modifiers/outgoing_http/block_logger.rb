module Loggun
  module Modifiers
    module OutgoingHttp
      class BlockLogger
        class << self
          %i[unknown fatal error warn info debug].each do |method|
            define_method(method) do |*args, &block|
              type = 'http_requests.outgoing.'
              type += caller[0][/request/] ? 'start' : 'response'
              Loggun.send(method, type, args, &block)
            end
          end
        end
      end
    end
  end
end
