#!/usr/bin/env ruby
#encoding: UTF-8
require_relative 'json_socket'
require_relative 'server2'     # For the default port

module Laink; end
class Laink::Client
  attr_reader :name
  def initialize
    @server = nil
    @name   = "Client #{rand(10000).to_s(36)}"
    @count  = 0
  end

  def connected?
    @server && !@server.closed?
  end

  def disconnect
    @server.close
    @server = nil
  end

  def connect( ip="localhost", port=Laink::Server::DEFAULT_PORT )
    disconnect if connected?
    begin
      socket = TCPSocket.new( ip, port ) #FIXME: timeout
      @server = Laink::JSONAsyncStatefulSocket.new( socket, &method(:handle_message) )
    rescue Errno::ECONNREFUSED => e
      warn "Could not connect to #{ip}:#{port}."
      raise
    end
  end

  def run
    connect unless connected?
    5.times{ |i|
      @server.send_data command:"Hello ##{i}", source:name
      sleep rand(3)
    }
    @server.send_data "Goodbye!"
  end

  def handle_message( message, jsocket )
    @count += 1
    puts "I just heard message ##{@count}: #{message.inspect}"
  end
end

Laink::Client.new.run if __FILE__==$0