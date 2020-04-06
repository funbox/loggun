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

### Конфигурация
Для успешной конфигурации гема необходимо подгружать файл при инициализации вашего приложения.

`config/initializers/loggun.rb`

```ruby
Loggun::Config.configure do |config|
  config.precision = :milliseconds
  config.pattern = '%{time} - %{pid} %{severity} %{type} %{tags_text} %{message}'
  config.parent_transaction_to_message = false

  config.modifiers.rails = true
  config.modifiers.sidekiq = false
  config.modifiers.clockwork = false
  config.modifiers.incoming_http = false
  config.modifiers.outgoing_http = false
end
```
Все настройки являются опциональными.
#### Настройки
`precision` - точность отметок времени. По умолчанию - `milliseconds`. Может принимать одно из следующих значений: `sec`, `seconds`, `ms`, `millis`, `milliseconds`, `us`, `micros`, `microseconds`, `ns`, `nanos`, `nanoseconds`

`pattern` - шаблон для формата вывода данных в лог. Доступные ключи: `time`, `pid`, `severity`, `type`, `tags_text`, `message`, `parent_transaction`

`parent_transaction_to_message` - признак необходимости добавлять значение `parent_transaction` в тело логируемого сообщения. 
Вне зависимости от данной настройки можно использовать ключ `parent_transaction` в шаблоне `pattern`.

`modifiers` - модификаторы для переопределения формата логирования указанного компонента. См. далее.

#### Модификаторы
Каждый модифкатор может быть активирован двумя равнозначными способами:
```ruby
config.modifiers.rails = true
```
или
```ruby
config.modifiers.rails.enable = true
```

`rails` - модифицирует форматирование логгера Rails.

`sidekiq` - модифицирует форматирование логгера Sidekiq.

`clockwork` - модифицирует форматирование логгера Clockwork.

`outgoing_http` - добавляет логирование исходящих http запросов. 
На данный момент поддерживаются только запросы посредством гема `HTTP`.

`incoming_http` - добавляет логирование входящих http запросов для контроллеров Rails.
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

`controllers` - массив имён базовых контроллеров, для которых необходимо добавить указанное логирование.

`success_condition` - лямбда, определяющая, содержит ли успех ответ экшена. Например `-> { JSON.parse(response.body)['result'] == 'ok' }`

`error_info` - лямбда, позволяющая добавить в лог информацию об ошибке, содержащейся в неуспешном ответе экшена. 
Например `-> { JSON.parse(response.body)['error_code'] }`

Для Rails 6 и выше данный модификатор может работать некорректно. 
В этом случае можно указать в требуемом базовом контроллере строку:
```ruby
include Loggun::HttpHelpers
```
Это делает настройки `enable` и `controllers` модификатора безсполезными, 
однако позволяет гарантированно логировать входящие http запросы.

Настройки `success_condition` и `error_info` продолжают использоваться и могу быть установлены требуемым образом.

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
Даёт подобный вывод в лог:
```
2020-03-04T16:58:38.207+05:00 - 28476 INFO type_for_action.some_class.some_action#msg_id_1583323118203 - {"value":["Information"]}
2020-03-04T16:58:38.208+05:00 - 28476 INFO type_for_bar.some_class.bar#msg_id_1583323118207 - {"value":["Bar information"],"parent_transaction":"class.geo_location__actual_location.fetch_input#msg_id_1583323118203"}
```

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).