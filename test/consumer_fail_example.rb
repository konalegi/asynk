class FailExampleConsumer
  include Asynk::Consumer

  set_consume 'asynk_test.fail_exmaple.fail'
  set_queue_options durable: true, ack: true
  set_subscribe_arguments manual_ack: true
  set_concurrency 2

  rescue_from "Exception", with: :handle_exception

  def process(message)
    raise ArgumentError.new('some error occured')
    ack!
  end

  def handle_exception(ex)
    logger.error "raised from exception(#{ex.class.name}): #{ex.message}"
    logger.error ex.backtrace.join("\n")
  end
end