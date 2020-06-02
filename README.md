# Loggun

[![Sponsored by FunBox](https://funbox.ru/badges/sponsored_by_funbox_compact.svg)](https://funbox.ru)

[![Gem Version](https://badge.fury.io/rb/loggun.svg)](https://badge.fury.io/rb/loggun)
[![Build Status](https://travis-ci.org/funbox/loggun.svg?branch=master)](https://travis-ci.org/funbox/loggun)

## Описание
Loggun - это гем, позволяющий привести все логи приложения к единому формату

## Установка

Чтобы установить гем, добавьте в ваш Gemfile:

```ruby
gem 'loggun'
```

И выполните команду :

    $ bundle

## Использование
Вы можете использовать Loggun как обертку для вашего Logger. Для этого необходимо передать
ему инстанс вашего логгера и настроить его formatter:
```ruby
Loggun.logger = Rails.logger
Loggun.logger.formatter = Loggun::Formatter.new
```

Теперь вы можете использовать Loggun для логгирования в стандартизированном формате:
```ruby
Loggun.info('http_request.api.request', user_id: current_user.id)
#=> 2020-04-11T22:35:04.225+03:00 - 170715 INFO http_request.api.request - {"user_id": 5465}
...
Loggun.info('http_request.api.response', user_id: current_user.id, success: true)
#=> 2020-04-11T22:35:04.225+03:00 - 170715 INFO http_request.api.response - {"user_id": 5465, "success": true} 
``` 

Подробнее об конфигурации и использовании Loggun ниже.

### Конфигурация
Для успешной конфигурации гема необходимо подгружать файл при инициализации вашего приложения.

`config/initializers/loggun.rb`

```ruby
Loggun::Config.configure do |config|
  config.precision = :milliseconds
  config.pattern = '%{time} - %{pid} %{severity} %{type} %{tags_text} %{message}'
  config.parent_transaction_to_message = false
  config.message_format = :json

  config.modifiers.rails = true
  config.modifiers.sidekiq = false
  config.modifiers.clockwork = false
  config.modifiers.incoming_http = false
  config.modifiers.outgoing_http = false
end
```
Все настройки являются опциональными.
#### Настройки
- `precision` - точность отметок времени. По умолчанию - `milliseconds`. Может принимать одно из следующих значений: `sec`, `seconds`, `ms`, `millis`, `milliseconds`, `us`, `micros`, `microseconds`, `ns`, `nanos`, `nanoseconds`
- `pattern` - текстовый шаблон для формата вывода данных в лог. 
Доступные ключи: `time`, `pid`, `severity`, `type`, `tags_text`, `message`, `parent_transaction`
- `parent_transaction_to_message` - признак необходимости добавлять значение `parent_transaction` в тело логируемого сообщения. 
Вне зависимости от данной настройки можно использовать ключ `parent_transaction` в шаблоне `pattern`. 
- `message_format` - формат переменной message в шаблоне pattern. Доступны два формата: 
  - `:json` - `message` логгируется как json строка
  - `:key_value` - `message` логгируется в формате `key1=value1 key2=value2` 
- `modifiers` - модификаторы для переопределения формата логирования указанного компонента. См. далее.

#### Модификаторы
Каждый модифкатор может быть активирован двумя равнозначными способами:
```ruby
config.modifiers.rails = true
```
или
```ruby
config.modifiers.rails.enable = true
```

##### Rails модификатор 
`config.modifier.rails` - модифицирует форматирование логгера Rails.

##### Active Record модификатор
`config.modifier.active_record` - добавляет (именно добавляет, а не модифицирует) нового подписчика на SQL события.
SQL начинает дополнительно логгироваться в Loggun формате, severity - info. Например:
```text
2020-04-12T20:08:52.913+03:00 - 487257 INFO storage.sql.query - {"sql":"SELECT 1","name":null,"duration":0.837}
```
Пример настроек:
```ruby
Loggun::Config.configure do |config|
  #...
  config.modifiers.active_record.enable = true
  config.modifiers.active_record.log_subscriber_class_name = 'MyApp::MyLogSubscriber'
  config.modifiers.active_record.payload_keys = %i[sql duration]
  #...
end
```
- `log_subscriber_class_name` - имя класса, реализующего логирование sql события.
Необходим метод `#sql`. По-умолчанию `::Loggun::Modifiers::ActiveRecord::LoggunLogSubscriber`

- `payload_keys` - необходимые ключи в полезной нарзуке. Используется в дефолтном классе. Доступные
ключи: ```%i[sql name duration source]```.

##### Sidekiq модификатор 
`config.modifiers.sidekiq` - модифицирует форматирование логгера Sidekiq.

##### Clockwork модификатор
`config.modifiers.clockwork` - модифицирует форматирование логгера Clockwork.

##### Модификатор исходящих HTTP запросово
`config.modifiers.outgoing_http` - добавляет логирование исходящих http запросов. 
На данный момент поддерживаются только запросы посредством гема `HTTP`.

##### Модификатор входящих запросов в Rails
 `config.modifiers.incoming_http` - добавляет логирование входящих http запросов для контроллеров Rails.
Данный модификатор может иметь дополнительные настройки, которые устанавливаются следующим образом 
(приведены значения по умолчанию):

```ruby
Loggun::Config.configure do |config|
  #...
  config.modifiers.incoming_http.enable = true
  config.modifiers.incoming_http.controllers = ['ApplicationController']
  config.modifiers.incoming_http.success_condition = -> { response.code == '200' }
  config.modifiers.incoming_http.error_info = -> { nil }
  #...
end
```
- `controllers` - массив имён базовых контроллеров, для которых необходимо добавить указанное логирование.

- `success_condition` - лямбда, определяющая, содержит ли успех ответ экшена. Например `-> { JSON.parse(response.body)['result'] == 'ok' }`

- `error_info` - лямбда, позволяющая добавить в лог информацию об ошибке, содержащейся в неуспешном ответе экшена. 
Например `-> { JSON.parse(response.body)['error_code'] }`

**Для Rails 6 и выше данный модификатор может работать некорректно.** 
В этом случае можно указать в требуемом базовом контроллере строку:
```ruby
include Loggun::HttpHelpers
```
Это делает настройки `enable` и `controllers` модификатора безсполезными, 
однако позволяет гарантированно логировать входящие http запросы.

Настройки `success_condition` и `error_info` продолжают использоваться и могут быть установлены требуемым образом.

##### Персональные модификаторы
Помимо указанных модификаторов существует возможность добавить собственный. 
Необходимо уснаследовать его от `Loggun::Modifiers::Base` и указать в методе `apply` все необходимые действия.
```ruby
require 'sinatra/custom_logger'

class NewModifier < Loggun::Modifiers::Base
  def apply
    Loggun::Config.setup_formatter(Sinatra::CustomLogger)
  end
end
```
Затем необходимо добавить его при конфигурации гема.

```ruby
Loggun::Config.configure do |config|
  #...
  config.add_mofifier NewModifier
  #...
end
```

### Хелперы
Подключение хелперов в класс позволяет использовать методы логирования `log_info` и `log_error`, 
а также генерировать идентификатор транзации для каждого метода класса.

Например:
```ruby
class SomeClass
  include Loggun::Helpers

  log_options entity_action: :method_name, as_transaction: true, only: %i[download_data]

  def download_data
    log_info 'http_request', 'Information'
    # ... make http request here
    log_info 'http_response', success: true
  end
end
```
При вызове `#download_data` мы получим следующий вывод в лог:
```
2020-03-04T16:58:38.207+05:00 - 28476 INFO http_request.some_class.download_data#ffg5431_1583323118203 - {"message":["Information"]}
2020-03-04T16:58:38.208+05:00 - 28476 INFO http_response.some_class.download_data#ffg5431_1583323118203 - {"success": true}
```

**Важно**, что с хелпером log_options необходимо использовать только методы вида `log_<severity>`. 
Методы модуля `Loggun` не будут работать.

Список всех опций хелпера log_options:

- `entity_name` - имя сущности метода, string
- `entity_action` - действие сущности метода, string
- `as_transaction` - добавлять уникальный ID транзакции для метода, boolean
- `transaction_generator` - собственный генератор ID транзакции, lambda
- `log_all_methods` - признак необходимости применения хелпера ко всем методам, boolean
- `only` - список методов, для которых необходимо применить хелпер (работает только если `log_all_methods` - false), Array{Symbol}
- `except` - список методов, которые надо исключить для хелпера, Array{Symbol}
- `log_transaction_except` - список методов, логирование которых не нужно обогащать ID транзакции, Array{Symbol}

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).