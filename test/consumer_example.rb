class WalletEventsConsumer
  include Asynk::Consumer

  set_consume 'gm_backend.wallet.registration_completed'
  set_queue_options durable: true, ack: true
  set_subscribe_arguments manual_ack: true
  set_concurrency 2

  rescue_from ArgumentError, with: :handle_argument_error
  rescue_from "Exception", with: :handle_exception

  def process
  end
end