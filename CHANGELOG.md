# Changelog

## 0.7.0 - 2023-09-19
* fixes
  * Middleware Changes for Sidekiq 7.0

## 0.6.0 - 2020-09-22
* features
  * Sidekiq client middlware for logging enqueued jobs

## 0.5.1 - 2020-09-22
* fix
  * `message` string only in `log_format == :json`

## 0.5.0 - 2020-09-22
* features
  * `config.log_format` - for control full log rows format
  * `config.exclude_keys`, `config.include_keys` - for include or exclude keys from `:json` log_format

## 0.4.1 - 2020-07-28
* fixes
  * fill type with class name for empty `log_entity_name`

## 0.4.0 - 2020-06-02
* fixes
  * fix key_value join character to space
  * fix dummy dependency alerts
* features
  * add new const MESSAGE_FORMATS and test for checking the value of message_format
  * add check message_format
  * boolean flag replace with a whitelist and create method for generating a message
  * added ability to log messages format k=v

## 0.3.1 - 2020-04-21
* fixes
  * fix error "modify frozen String" for class name in helpers

## 0.3.0 - 2020-04-17
* fixes
  * make public #generate_log_transaction_id in helper
  * removed incoming http modifier

## 0.2.0 - 2020-04-13
* fixes
  * fix Readme with active_record modifier
  * fix except option for helper #log_options
  * refactor helpers #log_type
  * fix helper define log_methods caller
  * improve stability of helpers
* features
  * remove legacy agent from default log pattern
  * new active record modifier
  * improve sidekiq modifier for difference versions
