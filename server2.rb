#!/usr/bin/env ruby
#encoding: UTF-8

require 'socket'
require 'json'
module Laink; end

class Laink::JSONSocket
  attr_reader :socket, :address
  def initialize( socket )
    @socket  = socket
    @address = "%s:%i" % @socket.remote_address.ip_unpack
  end
  def send_data( data )
    json  = data.to_json
    bytes = json.length
    unless @socket.closed?
      @socket.write [bytes].pack('n')
      unless @socket.closed?
        @socket.write json
      end
    end
  end
  def read_data
    begin
      bytes = @socket.read(2)
      raise IOError.new("no byte header") unless bytes && bytes.length==2
      bytes = bytes.unpack('n').first
      json  = @socket.read(bytes)
      raise IOError.new("not enough JSON data") unless json && json.length==bytes
      JSON.parse("[#{json}]",symbolize_names:true)[0]
    rescue JSON::ParserError => e
      warn "Failed to parse JSON response: #{json.inspect}; #{e}"
    rescue IOError => e
      @socket.close
    end
  end
  def closed?
    @socket.closed?
  end  
end

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