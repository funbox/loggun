module Loggun
  module Modifiers
    class IncomingHttp < Loggun::Modifiers::Base
      def apply
        return unless defined?(ActionPack)

        controllers = Loggun::Config.instance.modifiers.incoming_http.controllers
        controllers.each do |controller|
          controller.constantize.class_eval do
            include Loggun::HttpHelpers
          end
        end
      end
    end
  end
end
