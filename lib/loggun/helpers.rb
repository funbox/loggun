require 'securerandom'

module Loggun
  module Helpers
    SKIPPED_METHODS = %i[
      initialize loggun logger log_modified_methods loggun_init in_log_transaction with_log_type
    ].freeze
    DEFAULT_TYPE = 'class'.freeze

    def self.included(klass)
      klass.extend(InitMethods)
      klass.loggun_init
      klass.extend(ClassMethods)
    end

    module InitMethods
      attr_accessor(
        :with_log_transaction_id,
        :log_transaction_generator,
        :log_entity_name,
        :log_entity_action,
        :log_modified_methods,
        :log_skip_methods,
        :log_only_methods,
        :log_all_methods,
        :log_transaction_except
      )

      def loggun_init
        @log_modified_methods = []
        @log_all_methods = false
      end
    end

    module ClassMethods
      def log_options(**options)
        @log_entity_name = options[:entity_name]
        @log_entity_action = options[:entity_action]
        @with_log_transaction_id = options[:as_transaction]
        @log_transaction_generator = options[:transaction_generator]
        @log_transaction_except = options[:log_transaction_except]&.map(&:to_sym)
        @log_skip_methods = options[:except]&.map(&:to_sym)
        @log_only_methods = options[:only]&.map(&:to_sym)
        @log_all_methods = options[:log_all_methods]
      end

      def method_added(method_name)
        super
        @log_modified_methods ||= []

        return if !log_all_methods && !log_only_methods&.include?(method_name)
        return if log_skip_methods&.include?(method_name)
        return if SKIPPED_METHODS.include?(method_name) || log_modified_methods.include?(method_name)

        log_modified_methods << method_name
        method = instance_method(method_name)
        undef_method(method_name)

        define_method(method_name) do |*args, &block|
          if self.class.log_transaction_except&.include?(method_name.to_sym)
            method.bind(self).call(*args, &block)
          else
            type = log_type(nil, method_name)
            in_log_transaction(type) do
              method.bind(self).call(*args, &block)
            end
          end
        end
      end
    end

    %i[unknown fatal error warn info debug].each do |method_name|
      define_method("log_#{method_name}") do |*args, **attrs, &block|
        type = args.shift
        next logger.send(method_name, type, &block) if args.empty? && attrs.empty?

        caller_method_name = caller_locations.first.label.split(' ').last
        type = log_type(type, caller_method_name)

        if %i[fatal error].include?(method_name) && %i[backtrace message].all? { |m| args.first.respond_to?(m) }
          error = args.shift
          attrs[:error] = { class: error.class, msg: error.message }
          if attrs[:hidden]
            attrs[:hidden][:error] = { backtrace: error.backtrace }
          else
            attrs[:hidden] = { error: { backtrace: error.backtrace } }
          end
        end
        attrs[:message] = args unless args.empty?

        with_log_type(type) do
          logger.send(method_name, **attrs, &block)
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

    def in_log_transaction(current_type = nil, current_transaction_id = nil)
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

    def with_log_type(current_type)
      previous_type = self.type
      self.type = current_type
      yield
    ensure
      self.type = previous_type
    end

    def log_type(type, method_name)
      klass = self.class
      type ||= DEFAULT_TYPE.dup
      type_as_arr = type.split('.')

      log_entity_name = klass.respond_to?(:log_entity_name) ? klass.log_entity_name : underscore(klass.name)
      type_as_arr << log_entity_name if type_as_arr.size == 1

      return type unless klass.respond_to?(:log_entity_action)

      if klass.log_entity_action && klass.log_entity_action == :method_name && type_as_arr.size < 3 && method_name
        type_as_arr << method_name
      end

      type_as_arr.join('.')
    end

    def generate_log_transaction_id
      if self.class.log_transaction_generator
        return self.class.log_transaction_generator.call(self)
      end

      "#{SecureRandom.uuid[0..7]}_#{DateTime.now.strftime('%Q')}"
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

    def logger
      Loggun.logger
    end
  end
end