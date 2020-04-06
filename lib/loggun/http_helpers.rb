module Loggun
  module HttpHelpers
    def self.included(klass)
      klass.class_eval do
        around_action :log_http_actions
      end
    end

    private

    def log_http_actions
      log_action :start
      yield
      log_action :response
    rescue StandardError => e
      log_action :response, fail: e
      raise e
    end

    def log_action(action = :start, fail: nil)
      api = request.path[/\w+/]
      api_version = request.path[/v./]
      type = "http_request.#{api}.#{action}"
      data = { path: clean_pathname }
      data[:api_version] = api_version if api_version

      return Loggun.info type, data if action == :start

      success = fail.nil? && instance_exec(&modifier_config.success_condition)
      data[:success] = success
      unless success
        error = instance_exec(&modifier_config.error_info)
        data[:error] = error if error
      end
      Loggun.info type, data
    end

    def clean_pathname
      filtered_params = params.to_unsafe_h
      filtered_params.delete('action')
      request.path.gsub(/(#{filtered_params.values.join('|')})/, '').gsub(/\/api\/v./, '')
    end

    def modifier_config
      Loggun::Config.instance.modifiers.incoming_http
    end
  end
end