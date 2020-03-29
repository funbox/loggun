require 'clockwork/manager'

Clockwork::Manager.class_eval do
  def configure_loggun
    yield(config)
    setup_formatter
    if config[:sleep_timeout] < 1
      config[:logger].warn 'sleep_timeout must be >= 1 second'
    end
  end

  private

  def setup_formatter
    return unless Loggun::Config.instance.modifiers.clockwork

    Loggun::Config.setup_formatter(self)
  end
end

