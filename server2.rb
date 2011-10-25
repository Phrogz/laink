#!/usr/bin/env ruby
#encoding: UTF-8

require 'socket'
require 'json'
module Laink
  module ReadWriteJSON
    def send_data( data )
      json = data.to_json
      bytes = json.length
      write( [bytes].pack('n') )
      write( json )
    end
    def get_data      
      begin
        bytes = read(2)
        raise IOError unless bytes && bytes.length==2
        bytes = bytes.unpack('n').first
        json  = read(bytes)
        raise IOError unless json && json.length==bytes
        JSON.parse("[#{json}]",symbolize_names:true)[0]
      rescue JSON::ParserError => e
        warn "Failed to parse JSON response: #{json.inspect}; #{e}"
      rescue IOError => e
        connection.close
        warn "Connection closed...ignoring."
      end
    end
  end
end

class Laink::Server
  DEFAULT_PORT = 54147
  def initialize( port=DEFAULT_PORT )
    server = TCPServer.new(port)
    puts "Starting #{self.class} on %s:%i" % server.local_address.ip_unpack
    loop do
      Thread.start(server.accept) do |socket|
        begin
          socket.extend Laink::ReadWriteJSON
          reader = Thread.new{ loop{
            break if socket.closed?
            handle_message( socket, socket.get_data)
          } }
          10.times{ |i|
            break if socket.closed?
            socket.send_data command:"Hello ##{i}", source:"Server"
            sleep rand(3)
          }
        ensure
          puts "Closing from %s:%i" % socket.local_address.ip_unpack
          socket.close
        end
      end
    end
  end
  def handle_message( socket, message )
    puts "I just heard #{message.inspect}"
  end
end

Laink::Server.new if __FILE__==$0