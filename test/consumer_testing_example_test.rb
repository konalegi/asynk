require 'test_helper'
require 'consumer_example'

class ConsumerTestingExampleTest < Minitest::Test
  include Asynk::TestHelper
  def setup
  end

  def test_should_create_wallet_for_with_start_creation_failure
    message = { name: 'Pes', surname: 'Kotovskiy' }
    response = publish_sync 'sample_app.wallet.registration_completed', message
    assert_equal message.to_json, response

    response = publish_sync 'sample_app.logs.warn', message
    assert_equal message.to_json, response

    response = publish_sync 'sample_app.logs.info', message
    assert_equal message.to_json, response

  end
end