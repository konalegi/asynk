require 'celluloid'
require 'celluloid/io'
require 'celluloid/autostart'
require 'bunny'

class Worker
  include Celluloid::IO
  finalizer :shutdown

  def initialize(conn)
    @ch = conn.create_channel
    q = @ch.queue('task_queue', :durable => true)
    q.subscribe manual_ack: true, &method(:on_subscribe)
    p 'worker accepting connections'
  end

  def on_subscribe(delivery_info, properties, body)
    p "#{Time.now.strftime('%FT %T.%L')} started work: #{body}"
    sleep(10)
    p "#{Time.now.strftime('%FT %T.%L')} completed work: #{body}"
    @ch.ack(delivery_info.delivery_tag)
  end

  def shutdown
    p 'trying to shutdown...'
    @ch.close
    p 'hey shutdown'
  end
end

class Consumer
  def initialize(options = {})
    @size = (ENV['POOL'] || 2).to_i
    @connection = Bunny.new(options)
    @connection.start
    @workers = @size.times.map{ Worker.new(@connection) }
  end

  def close_connection
    futures = @workers.map { |w| w.future(:finalize) }
    @connection.close if futures.all?
  end
end

begin
  @consumer = Consumer.new
rescue Interrupt => _
  @consumer.close_connection
end

sleep

