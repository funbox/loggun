require_relative 'incoming_http/log_http_actions'

module Loggun
  module Modifiers
    class IncomingHttp < Loggun::Modifiers::Base
      def apply
        return unless defined?(ActionPack)

        Loggun::Config.instance.controllers.each do |controller|
          controller.constantize.class_eval do
            include LogHttpActions
            around_action :log_http_actions
          end
        end
      end
    end
  end
end
