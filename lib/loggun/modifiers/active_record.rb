module Loggun
  module Modifiers
    class ActiveRecord < Loggun::Modifiers::Base
      def apply
        return unless defined?(::ActiveRecord) && defined?(::ActiveRecord::LogSubscriber)

        subscriber_class_name = config.modifiers.active_record.log_subscriber_class_name
        if subscriber_class_name == ::Loggun::Config::DEFAULTS[:active_record][:log_subscriber_class_name]
          require 'loggun/modifiers/active_record/loggun_log_subscriber'
        end
        klass = Object.const_get(subscriber_class_name)

        return klass.attach_to :active_record if klass.respond_to?(:attach_to)

        Loggun.warn(
          "Loggun: passed active_record.log_subscriber_class_name `#{subscriber_class_name}`" \
          "must respond to #attached_to method"
        )
      end
    end
  end
end
