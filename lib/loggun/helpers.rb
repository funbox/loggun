require 'securerandom'

module Loggun
  module Helpers
    SKIPPED_METHODS = %i[
      initialize loggun logger modified_methods
    ].freeze
    DEFAULT_TYPE = 'class'.freeze

    def self.included(klass)
      klass.extend(ClassMethods)
      klass.init
    end

    module ClassMethods
      attr_accessor(
        :with_log_transaction_id,
        :log_transaction_generator,
        :log_entity_name,
        :log_entity_action,
        :modified_methods,
        :generate_transaction_except
      )

      def log_options(**options)
        @log_entity_name = options[:entity_name]
        @log_entity_action = options[:entity_action]
        @with_log_transaction_id = options[:as_transaction]
        @log_transaction_generator = options[:transaction_generator]
        @generate_transaction_except = options[:generate_transaction_except]&.map(&:to_sym)
      end

      def init
        @modified_methods = []
      end

      def method_added(method_name)
        super
        @modified_methods ||= []
        return if SKIPPED_METHODS.include?(method_name) ||
                  modified_methods.include?(method_name)

        modified_methods << method_name
        method = instance_method(method_name)
        undef_method(method_name)

        define_method(method_name) do |*args, &block|
          if self.class.generate_transaction_except&.include?(method_name.to_sym)
            method.bind(self).call(*args, &block)
          else
            type = log_type(nil, method_name)
            in_transaction(type) do
              method.bind(self).call(*args, &block)
            end
          end
        end
      end
    end

    %i[unknown fatal error warn info debug].each do |method|
      define_method("log_#{method}") do |*args, **attrs, &block|
        type = args.shift
        next application.logger.send(method, type, &block) if args.empty? &&
                                                              attrs.empty?

        method_name = caller_locations.first.label.split(' ').last
        type = log_type(type, method_name)

        if %i[fatal error].include?(method)
          methods = args.first.methods
          next unless methods.include?(:message) && methods.include?(:backtrace)

          error = args.shift
          attrs[:error] = { class: error.class, msg: error.message }
          if attrs[:hidden]
            attrs[:hidden][:error] = { backtrace: error.backtrace }
          else
            attrs[:hidden] = { error: { backtrace: error.backtrace } }
          end
        end
        attrs[:value] = args if args.present?

        with_type(type) do
          application.logger.send(method, **attrs, &block)
        end
      end
    end

    %w[type transaction_id].each do |method_name|
      %I[#{method_name} parent_#{method_name}].each do |method|
        define_method(method) { Thread.current["loggun_#{method}".to_sym] }

        define_method("#{method}=") do |value|
          value = normalize(value) if method == :type

          Thread.current["loggun_#{method}".to_sym] = value
        end
      end
    end

    def in_transaction(current_type = nil, current_transaction_id = nil)
      current_transaction_id ||= generate_log_transaction_id
      previous_transaction_id = self.parent_transaction_id
      previous_type = self.parent_type

      self.parent_transaction_id = self.transaction_id
      self.parent_type = self.type

      self.transaction_id = current_transaction_id
      self.type = current_type if current_type
      yield
    ensure
      self.transaction_id = self.parent_transaction_id
      self.type = self.parent_type

      self.parent_transaction_id = previous_transaction_id
      self.parent_type = previous_type
    end

    def with_type(current_type)
      previous_type = self.type
      self.type = current_type
      yield
    ensure
      self.type = previous_type
    end

    def log_type(type, method_name)
      type ||= DEFAULT_TYPE.dup
      type_as_arr = type.split('.')
      klass = self.class
      log_entity_name = klass.log_entity_name if klass.respond_to?(:log_entity_name)
      log_entity_name ||= underscore(klass.name)
      type << ".#{log_entity_name}" if type_as_arr.size == 1

      return type unless klass.respond_to?(:log_entity_action)

      if klass.log_entity_action && type_as_arr.size < 3
        if klass.log_entity_action == :method_name && method_name
          type << ".#{method_name}"
        end
      end

      type
    end

    private

    def normalize(type)
      return unless type

      type = type.to_s.strip.tr(" \t\r\n", ' ').squeeze(' ')
      type.empty? ? nil : type
    end

    def underscore(word)
      word.gsub!(/::/, '__')
      word.gsub!(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
      word.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
      word.tr!('-', '_')
      word.downcase!
      word
    end

    def generate_log_transaction_id
      return unless self.class.with_log_transaction_id
      if self.class.log_transaction_generator
        return self.class.log_transaction_generator.call
      end

      "#{SecureRandom.uuid[0..7]}_#{DateTime.now.strftime('%Q')}"
    end

    def application
      Loggun.application
    end
  end
end