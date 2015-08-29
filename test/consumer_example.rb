class WalletEventsConsumer
  include Asynk::Consumer

  set_consume 'gm_backend.wallet.registration_completed'
  set_queue 'wallet_events', durable: true, ack: true
  set_subscribe_arguments manual_ack: true
  set_concurrency 2

  def process
  end
end