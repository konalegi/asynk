class WalletEventsConsumer
  include Asynk::Consumer

  set_consume 'gm_backend.kroter_wallet.*'
  set_queue 'gm_backend.kroter_wallet_queue', durable: true, ack: true
  set_subscribe_arguments manual_ack: true
  set_concurrency 2
  set_sync true

  def process(msg)
    # logger.info "Msg received: #{msg}"
    # raise 'Inpropriate User' if msg[:name] == 'Insaf'

    # user = User.create(name: msg['name'], surname: msg['surname'])
    # logger.info ['count: ', User.count].join(' ')
    ack!
    Asynk::Response.new(status: :ok)
  rescue Exception => e
    reject!
    Asynk::Response.new(status: :failed, error_message: e.message )
  end
end