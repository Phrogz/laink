#!/usr/bin/env ruby
#encoding: UTF-8
require_relative 'json_socket'
module Laink; end
class Laink::Server
  DEFAULT_PORT = 54147
  def initialize( port=DEFAULT_PORT )
    server = TCPServer.new(port)
    puts "Starting #{self.class} on %s:%i" % server.local_address.ip_unpack
    @messages = 0
    loop do
      Thread.start(server.accept) do |socket|
        client = Laink::JSONAsyncStatefulSocket.new(socket) do |message, c|
          puts "[#{@messages += 1}] I just heard #{message.inspect} from #{c.address}"
        end
        begin
          10.times{ |i|
            sleep rand(3)
            break unless client.send_data command:"G'day ##{i}", source:"Server"
          }
        ensure
          puts "Closing connection to #{client.address}"
          socket.close unless socket.closed?
        end
      end
    end
  end
end

Laink::Server.new if __FILE__==$0