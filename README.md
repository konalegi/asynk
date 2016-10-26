# Asynk

Asynk is a Ruby library for enabling synchronous/asynchronous inter-service communication, using RabbitMQ.

# Overview

It's takes concepts of ruby gem called Hutch, but using Cellouid under hood for creating workers for processing queues, which requires significant memory requirements.
Also as limitation of ruby you cannot make heavy computations in ruby and gather true concurrency. Asynk offers synchronous calls (RPC).

## Installation

Add this line to your application's Gemfile:

    gem 'asynk'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install asynk

## Usage


Firstly you should define consumer, Example of consumer

```ruby
class V1::PaymentOrdersConsumer
  include Asynk::Consumer  

  set_consume 'sample_app.v1.users.create', 'sample_app.v1.users.notifications'

  set_queue_options ack: true
  set_subscribe_arguments manual_ack: true
  set_concurrency 2
  set_route_ending_as_action true  

  # handling asynchronous request from amqp
  def notifications(params)    
    # do here some works
  ensure
    ack! # required if you manually processing acknowledgments, available methods reject!, requeue!
  end

  # example for handling synchronous request
  def create(params)
    result = my_method # here we doing some work, and saving result of
    result = Asynk::Response.new(status: :ok, body: result) # result should any object which implements to_json.
    respond(result) # if producer expecting response, we should response with some data.
                    # Is not required to use any format of response. But preferred way is to use class Asynk::Response,
                    # which used as lightweight implementation of http. (Containing body, status, and error_message).
  ensure
    ack!
  end
end
```

Firstly you should define Class, and include Asynk::Consumer.
  * `set_consume` list of topics to consume
  * `set_queue_options` set for options which created after server initialized
  * `set_subscribe_arguments` set options which passed to when subscribing queue to exchange
  * `set_concurrency` amount of workers which will consume for each consumer
  * `set_route_ending_as_action` this options defines, that last item of consume topic is used as method name (ex: sample_app.v1.users.show, last item show, will be called in this class.)

Also, after instance creation, has several methods,
  * `log` logger object for sending logs for default Logger of Asynk.
  * `ack!`, `reject!`, `requeue!`  methods is used for handling messages, if you want manually work with acknowledgments



After declaring consumer, now you can send some request using default Asynk::Publisher, it has two options:
  * `sync_publish` synchronous sending of message, and waiting for response from consumer. You should define timeouts, if consumers crashes it never receives a             message. timeout - says the amount of time in seconds for waiting message, if timeout reaches it sends TimeoutError.
  * `publish` just sending message, and forgets about it.

```ruby
  # here sending synchronous messages
  Asynk::Publisher.sync_publish('sample_app.v1.users.create', { name: 'Tom', surname: 'Lane', timeout: 10 })

  # here sending asynchronous messages
  Asynk::Publisher.publish('sample_app.v1.users.notifications', { name: 'Tom', surname: 'Lane' })
```


Asynk is using pool for channels for receiving and sending messages.
Usage in rails, should initialize authentication data and init connection to RabbitMQ server.

```ruby
# Init authentication
Asynk.config[:mq_host] = ENV['MQ_HOST']
Asynk.config[:mq_username] = ENV['MQ_USERNAME']
Asynk.config[:mq_password] = ENV['MQ_PASSWORD']

# Init connection to server.
Asynk::Broker.connect

# here we initializing logger.
if Rails.env.stage? || Rails.env.production?
  if Asynk.booted_inside? # if we booting inside asynk, it's separate process than rails server.
    Asynk.logger.level = ::Logger::DEBUG
  else # If we booted inside  rails project, we can use rails's logger.
    Asynk.logger = Rails.logger
  end
else
  Asynk.logger.level = ::Logger::INFO
  Asynk.config[:publisher_execution_time] = false
end

```
## Config options
* `mq_exchange` exchange to use for publishing (`default` 'asynk_exchange_topic')
* `sync_publish_wait_timeout` time to wait for sync requests. If timeout reaches, the timeout raised. (`default` 10 seconds)
* `default_consumer_concurrency` numbers of workers to start per consumer (`default` 1)
* `logfile` log file for default logger of asynk (`default` 'log/asynk.log')
* `pidifle`  Asynk consumers is running on different process, this file is used to store pid file (`default` 'tmp/pids/asynk.pid')
* `mq_host`  host for connection to broker (RabbitMQ) (`default` 'localhost')
* `mq_port`  port for connection to broker (RabbitMQ) (`default` 5672)
* `mq_vhost` vhost for connection to broker (RabbitMQ) (`default` '/')
* `mq_username` username for connection to broker (RabbitMQ) (`default` 'guest')
* `mq_password` password for connection to broker (RabbitMQ) (`default` 'guest')
* `publisher_execution_time` used for profiling time to send when using Asynk::Publisher (`default` true)
* `respond_back_execution_time` used for profiling time used for processing sync response (`default` true)
* `ignored_consumers` this parameter used for disabling unused consumers as array of strings with consumer class names(`default` [])


# Testing your consumers
Firstly you should include `Asynk::TestHelper` to your test class, and then call `sync_publish` method for sending request, if this is rpc call,
invoke the asynk_response method for getting response.

Example using with Rails and MiniTest.
```ruby
  # test_helper.rb
  class ActiveSupport::TestCase
    # include the test helper.  
    include Asynk::TestHelper

    # wrapping the response with Asynk::Response class, otherwise it will be just string value.
    def asynk_response
      Asynk::Response.try_to_create_from_hash(super)
    end
  end


  # some_consumer_test.rb  

  test 'should show profile' do
    publish_sync 'some_route', { name: 'Chris' }

    assert asynk_response.success? # testing for status of the response
    assert asynk_response[:unread_messages] # testing the returned data
    assert asynk_response[:unread_message_count]    
  end
```
## Disabling consumers
If you have application that have multiple different consumers, you can disable some of them by setting ignored_consumers parameter.

For example, if you have application that implements media file processing consumers - TranscodeVideoConsumer, ResizeImageConsumer, CutAudioConsumer and you want one server only to transcode video files.

You have to set ignored_consumers parameter before connecting to server

```ruby
Asynk.config[:ignored_consumers] = ['ResizeImageConsumer', 'CutAudioConsumer']
```

Also you can set ignored consumers in string environment variable

```bash
export IGNORED_CONSUMERS=ResizeImageConsumer,CutAudioConsumer
```

and then in Asynk initializer

```ruby
Asynk.config[:ignored_consumers] = ENV['IGNORED_CONSUMERS'].delete(' ').split(',') if ENV['IGNORED_CONSUMERS']
```

## Known problems

* Poor documentation (source are poorly documented)
* Poor test coverage (there are almost no test)
* RPC calls implementation. Currently is implemented as continues loop, which tries get data from reply queue. Before it was implemented using Mutex, which caused huge time usage on handling them. I am not sure that current implementation is correct, but is id much faster in current tests. (On my machine 1-2 ms vs 7-8 ms).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/gm_server/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
