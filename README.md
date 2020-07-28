# Loggun

[![Gem Version](https://badge.fury.io/rb/loggun.svg)](https://badge.fury.io/rb/loggun)
[![Build Status](https://travis-ci.org/funbox/loggun.svg?branch=master)](https://travis-ci.org/funbox/loggun)

Приводит логи приложения к единому формату.

## Содержание

- [Установка](#установка)
- [Использование](#использование)
- [Конфигурация](#конфигурация)
  - [Настройки](#настройки)
  - [Модификаторы](#модификаторы)
    - [Rails модификатор](#rails-модификатор)
    - [Active Record модификатор](#active-record-модификатор)
    - [Sidekiq модификатор](#sidekiq-модификатор)
    - [Clockwork модификатор](#clockwork-модификатор)
    - [Модификатор исходящих HTTP-запросов](#модификатор-исходящих-http-запросов)
    - [Модификатор входящих запросов в Rails](#модификатор-входящих-запросов-в-rails)
    - [Пользовательские модификаторы](#пользовательские-модификаторы)
  - [Хелперы](#хелперы)

## Установка

Чтобы установить гем, добавьте его в Gemfile:

```ruby
gem 'loggun'
```

И выполните команду:

```bash
$ bundle
```

## Использование

Loggun можно использовать как обертку для вашего `logger`. Для этого необходимо передать
ему инстанс логгера и настроить его `formatter`:

```ruby
Loggun.logger = Rails.logger
Loggun.logger.formatter = Loggun::Formatter.new
```

Теперь можно использовать Loggun для логирования в стандартизированном формате:

```ruby
Loggun.info('http_request.api.request', user_id: current_user.id)
#=> 2020-04-11T22:35:04.225+03:00 - 170715 INFO http_request.api.request - {"user_id": 5465}
...
Loggun.info('http_request.api.response', user_id: current_user.id, success: true)
#=> 2020-04-11T22:35:04.225+03:00 - 170715 INFO http_request.api.response - {"user_id": 5465, "success": true} 
``` 

## Конфигурация

Конфигурацию гема необходимо производить при инициализации приложения. Например, так:

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

### Настройки

Все настройки опциональны.

- `precision` — точность отметок времени.

  Может принимать одно из следующих значений:
  `sec`, `seconds`, `ms`, `millis`, `milliseconds`, `us`, `micros`, `microseconds`, `ns`, `nanos`, `nanoseconds`.
  
  По умолчанию `milliseconds`.

- `pattern` — текстовый шаблон для формата вывода данных в лог.   

  Доступные ключи внутри шаблона: `time`, `pid`, `severity`, `type`, `tags_text`, `message`, `parent_transaction`.

- `parent_transaction_to_message` — если `true`, то значение `parent_transaction` будет добавлено в тело логируемого сообщения.
 
  Ключ `parent_transaction` в шаблоне `pattern` можно использовать вне зависимости от значения этой настройки. 

- `message_format` — формат переменной `message` в шаблоне `pattern`. 

  Доступные значения:
   
  - `:json` — `message` логируется как JSON-строка;
  - `:key_value` — `message` логируется в формате `key1=value1 key2=value2`.
 
- `modifiers` — модификаторы для переопределения формата логирования указанного компонента. См. «[Модификаторы](#модификаторы)».

### Модификаторы

Каждый модифкатор может быть активирован двумя равнозначными способами:

```ruby
config.modifiers.rails = true
```

или

```ruby
config.modifiers.rails.enable = true
```

(В качестве примера активируется Rails модификатор, но может быть любой другой.)

#### Rails модификатор 

`config.modifier.rails`

Модифицирует форматирование логгера Rails.

#### Active Record модификатор

`config.modifier.active_record`

Добавляет (именно добавляет, а не модифицирует) нового подписчика на SQL-события.

SQL начинает дополнительно логироваться в Loggun формате, `severity` — `info`. Например:

```text
2020-04-12T20:08:52.913+03:00 - 487257 INFO storage.sql.query - {"sql":"SELECT 1","name":null,"duration":0.837}
```

Дополнительные настройки:

- `log_subscriber_class_name` — имя класса, реализующего логирование SQL-события.

  Необходим метод `#sql`. По умолчанию: `::Loggun::Modifiers::ActiveRecord::LoggunLogSubscriber`.

- `payload_keys` — необходимые ключи в полезной нарзуке. Используется в классе по умолчанию. 
   
  Доступные ключи: `%i[sql name duration source]`.

Пример:

```ruby
Loggun::Config.configure do |config|
  #...
  config.modifiers.active_record.enable = true
  config.modifiers.active_record.log_subscriber_class_name = 'MyApp::MyLogSubscriber'
  config.modifiers.active_record.payload_keys = %i[sql duration]
  #...
end
```

#### Sidekiq модификатор 

`config.modifiers.sidekiq`

Модифицирует форматирование логгера Sidekiq.

#### Clockwork модификатор

`config.modifiers.clockwork`
 
Модифицирует форматирование логгера Clockwork.

#### Модификатор исходящих HTTP-запросов

`config.modifiers.outgoing_http`

Добавляет логирование исходящих HTTP-запросов. 
На данный момент поддерживаются только запросы, выполненные с помощью гема `HTTP`.

#### Модификатор входящих запросов в Rails

 `config.modifiers.incoming_http`
 
Добавляет логирование входящих HTTP-запросов для контроллеров Rails.

Может иметь дополнительные настройки:

- `controllers` — массив имён базовых контроллеров, для которых необходимо добавить указанное логирование.

- `success_condition` — лямбда, определяющая, содержит ли успех ответ экшена.

  Например: `-> { JSON.parse(response.body)['result'] == 'ok' }`

- `error_info` — лямбда, позволяющая добавить в лог информацию об ошибке, содержащейся в неуспешном ответе экшена. 

  Например: `-> { JSON.parse(response.body)['error_code'] }`


Пример (приведены значения по умолчанию):

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

**Для Rails 6 и выше данный модификатор может работать некорректно.** 

В этом случае можно добавить в требуемый базовый контроллер строку:

```ruby
include Loggun::HttpHelpers
```

Это делает настройки `enable` и `controllers` модификатора безсполезными, 
однако позволяет гарантированно логировать входящие HTTP-запросы.

Настройки `success_condition` и `error_info` продолжают использоваться и могут быть установлены требуемым образом.

#### Пользовательские модификаторы

Помимо указанных модификаторов существует возможность добавить собственный. 
Необходимо уснаследовать его от `Loggun::Modifiers::Base` и указать в методе `apply` все необходимые действия:

```ruby
require 'sinatra/custom_logger'

class NewModifier < Loggun::Modifiers::Base
  def apply
    Loggun::Config.setup_formatter(Sinatra::CustomLogger)
  end
end
```

Затем необходимо добавить его при конфигурации гема:


```ruby
Loggun::Config.configure do |config|
  #...
  config.add_mofifier NewModifier
  #...
end
```

### Хелперы

Подключение хэлперов в класс позволяет использовать методы логирования `log_info` и `log_error`, 
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

При вызове `#download_data` будет следующий вывод в лог:

```
2020-03-04T16:58:38.207+05:00 - 28476 INFO http_request.some_class.download_data#ffg5431_1583323118203 - {"message":["Information"]}
2020-03-04T16:58:38.208+05:00 - 28476 INFO http_response.some_class.download_data#ffg5431_1583323118203 - {"success": true}
```

**Важно**, что с хэлпером `log_options` необходимо использовать только методы вида `log_<severity>`. 
Методы модуля `Loggun` не будут работать.

Список всех опций хэлпера `log_options`:

- `entity_name` — имя сущности метода, `string`;
- `entity_action` — действие сущности метода, `string`;
- `as_transaction` — добавлять ли уникальный ID транзакции для метода, `boolean`;
- `transaction_generator` — собственный генератор ID транзакции, `lambda`;
- `log_all_methods` — применять ли хэлпер ко всем методам, `boolean`;
- `only` — список методов, для которых необходимо применить хэлпер (работает только когда `log_all_methods = false`), `Array{Symbol}`;
- `except` — список методов, которые надо исключить для хэлпера, `Array{Symbol}`;
- `log_transaction_except` — список методов, логирование которых не нужно обогащать ID транзакции, `Array{Symbol}`.

[![Sponsored by FunBox](https://funbox.ru/badges/sponsored_by_funbox_centered.svg)](https://funbox.ru)
