require 'bunny'

conn = Bunny.new
conn.start

ch = conn.create_channel
q  = ch.queue('task_queue', durable: true)

10.times do |index|
  msg = "Hello World! #{index}"
  q.publish(msg)
  puts " [x] Sent #{msg}"
end

conn.close