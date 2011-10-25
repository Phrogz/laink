#!/usr/bin/env ruby
#encoding: UTF-8
require_relative 'json_socket'
module Laink; end
class Laink::Server
  DEFAULT_PORT = 54147
  def initialize( port=DEFAULT_PORT )
    server = TCPServer.new(port)
    puts "Starting #{self.class} on %s:%i" % server.local_address.ip_unpack
    loop do
      Thread.start(server.accept) do |socket|
        client = Laink::JSONSocket.new(socket)
        begin
          reader = Thread.new{ loop{
            break if client.closed?
            handle_message( client, client.read_data )
          } }
          10.times{ |i|
            break if client.closed?
            client.send_data command:"G'day ##{i}", source:"Server"
            sleep rand(3)
          }
        ensure
          puts "Closing from #{client.address}"
          socket.close
        end
      end
    end
  end
  def handle_message( client, message )
    puts "I just heard #{message.inspect}" if message
  end
end

Laink::Server.new if __FILE__==$0