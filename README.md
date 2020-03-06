# Loggun

[![Sponsored by FunBox](https://funbox.ru/badges/sponsored_by_funbox_compact.svg)](https://funbox.ru)

[![Gem Version](https://badge.fury.io/rb/loggun.svg)](https://badge.fury.io/rb/loggun)
[![Build Status](https://travis-ci.org/funbox/loggun.svg?branch=master)](https://travis-ci.org/funbox/loggun)

## Description

Loggun is a gem for converting the formatting of application logs to a single type

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'loggun'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install loggun

## Usage

### Configure
`config/initializers/loggun.rb`

```ruby
Loggun::Config.configure do |config|
  config.pattern = '%{time} - %{pid} %{severity} %{type} %{tags_text} %{message}'

  config.modifiers.rails = true
  config.modifiers.sidekiq = false
  config.modifiers.clockwork = false
  config.modifiers.incoming_http = false
  config.modifiers.outgoing_http = false

  config.controllers = %w[ApplicationController]
  config.parent_transaction_to_message = true

  config.precision = :milliseconds
end
```

#### Settings
`precision` - timestamps precision. `milliseconds` by default. One of: `sec`, `seconds`, `ms`, `millis`, `milliseconds`, `us`, `micros`, `microseconds`, `ns`, `nanos`, `nanoseconds`

`pattern` - pattern for customizing output to the log. Available keys: `time`, `pid`, `severity`, `type`, `tags_text`, `message`, `parent_transaction`

`modifiers` - settings for enabling logging override for this component

`controllers` - array of base controllers for `incoming_http` modifier

`parent_transaction_to_message` - add parent transaction identifier to message body. If disabled, you can use `parent_transaction` in the `pattern`

### Log with transactions
```ruby
class SomeClass
  include Loggun::Helpers

  log_options entity_action: :method_name, as_transaction: true

  def some_action
    log_info 'type_for_action', 'Information'
    bar
  end

  def bar
    log_info 'type_for_bar', 'Bar information'
  end
end
```

```
2020-03-04T16:58:38.207+05:00 - 28476 INFO type_for_action.some_class.some_action#msg_id_1583323118203 - {"value":["Information"]}
2020-03-04T16:58:38.208+05:00 - 28476 INFO type_for_bar.some_class.bar#msg_id_1583323118207 - {"value":["Bar information"],"parent_transaction":"class.geo_location__actual_location.fetch_input#msg_id_1583323118203"}
```

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).