require 'test_helper'

class ConsumerLoadTest < Minitest::Test
  def test_load_consumer
    require 'consumer_example'
    assert_equal 2, WalletEventsConsumer.concurrency
    assert_equal 'wallet_events', WalletEventsConsumer.queue_name
    assert_equal ({ durable: true, ack: true }), WalletEventsConsumer.queue_options
    assert_equal ['gm_backend.wallet.registration_completed'], WalletEventsConsumer.routing_keys
    assert_equal ({ manual_ack: true }), WalletEventsConsumer.subscribe_arguments

    Asynk::Server.instance.run
    assert true
  end
end