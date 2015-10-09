class WalletEventsConsumer
  include Asynk::Consumer

  set_consume 'sample_app.wallet.registration_completed'
  set_queue_options durable: true, ack: true
  set_subscribe_arguments manual_ack: true
  set_concurrency 1
  set_route_ending_as_action true

  def registration_completed(message)
    respond(message.body)
  end
end

class LogEventsConsumer
  include Asynk::Consumer

  set_consume 'sample_app.logs.warn', 'sample_app.logs.info'
  set_queue_options durable: true, ack: true
  set_subscribe_arguments manual_ack: true
  set_concurrency 1
  set_route_ending_as_action true

  def warn(message)
    respond(message.body)
  end

  def info(message)
    respond(message.body)
  end
end