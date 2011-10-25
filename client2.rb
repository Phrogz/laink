#!/usr/bin/env ruby
#encoding: UTF-8
require_relative 'server2'

class Laink::Client
  def initialize
    @server = nil
  end

  def name
    @id ||= rand(10000).to_s(36)
    "Client #{@id}"
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
      @server = TCPSocket.new( ip, port ) #FIXME: timeout
      @server.extend Laink::ReadWriteJSON
    rescue Errno::ECONNREFUSED => e
      warn "Could not connect to #{ip}:#{port}."
      raise
    end
  end

  def send( data )
    @mutex.synchronize{ @queue << data }
    @writer.run
  end

  def handle_message( message )
    puts "I just heard #{message.inspect}"
  end

  def run
    connect unless connected?
    @reader = Thread.new{ loop{ handle_message @server.get_data } }
    5.times{ |i|
      @server.send_data command:"Hello ##{i}", source:name
      sleep rand(3)
    }
  end
end

Laink::Client.new.run if __FILE__==$0