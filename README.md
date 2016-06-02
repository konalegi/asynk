# Asynk

Asynk is a Ruby library for enabling synchronous/asynchronous inter-service communication, using RabbitMQ.

# Overview

It's takes concepts of ruby gem called Hutch, but using Cellouid under hood for creating workers for processing queues, which requires significant memory requirments.
Also as limitation of ruby you cannot make heavy computations in ruby and gather true concurency. Async offers synchronous calls (RPC).

## Installation

Add this line to your application's Gemfile:

    gem 'asynk'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install endive

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
    ack! # required if you manually processing acknolagments, available methods reject!, requeue!
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
  set_consume - list of topics to consume
  set_queue_options - set for options which created after server intialized
  set_subscribe_arguments - set options which passed to when subscribing queue to exchange
  set_concurrency - amount of workers which will consume for each consumer
  set_route_ending_as_action - this options defines, that last item of consume topic is used as method name (ex: sample_app.v1.users.show, last item show, will be called in this class.)

Also, after instance creation, has several methods,
  log - logger object for sending logs for default Logger of Asynk.
  ack!, reject!, requeue! - methods is used for handling messages, if you want manually work with ackonaldgments



After declaring consumer, now you can send some request using default Asynk::Publisher, it has two options:
  sync_publish - synchronous sending of message, and waiting for response from consumer. You should define timeouts, if consumers crashes it never receives a             message. timeout - says the amount of time in seconds for waiting message, if timeout reaches it sends TimeoutError.
  publish - just sending message, and forgets about it.

```ruby
  # here sending synchronous messages
  Asynk::Publisher.sync_publish('sample_app.v1.users.create', { name: 'Tom', surname: 'Lane', timeout: 10 })

  # here sending asynchronous messages
  Asynk::Publisher.publish('sample_app.v1.users.notifications', { name: 'Tom', surname: 'Lane' })
```

Library is made for interconnection for between microservices, it's highly recomended to use only asynchronous methods. If you making synchronous requests during any client request, it's bad design. Is you need some data from another microservice, just copy to your local store with eventually consistency.


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

## Contributing

1. Fork it ( https://github.com/[my-github-username]/gm_server/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request