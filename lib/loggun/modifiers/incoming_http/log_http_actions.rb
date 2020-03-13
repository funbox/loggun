module LogHttpActions

  private

  def log_http_actions
    log_action :start
    yield
    log_action :response
  end

  def log_action(action = :start)
    api = request.path[/\w+/]
    api_version = request.path[/v./]
    type = "http_request.#{api}.#{action}"
    data = { path: clean_pathname, api_version: api_version }
    if action == :response
      parsed_response = JSON.parse(response_body.first)
      success = parsed_response['result'] == 'ok'
      data[:success] = success
      data[:error] = parsed_response['error_code'] unless success
    end
    Loggun.log_info type, data
  end

  def clean_pathname
    filtered_params = params.to_unsafe_h
    filtered_params.delete('action')
    request.path.gsub(/(#{filtered_params.values.join('|')})/, '').gsub(/\/api\/v./, '')
  end
end