#encoding: UTF-8
require 'json'
require 'socket'

module Laink; end
class Laink::JSONAsyncStatefulSocket
  attr_reader :socket, :address
  def initialize( socket )
    @socket  = socket
    @address = "%s:%i" % @socket.remote_address.ip_unpack
    Thread.new{ while message=read_data; yield(message, self); end }
  end
  # Returns nil for a closed connection
  def read_data
    begin
      return if @socket.closed?
      bytes = @socket.read(2)
      raise IOError.new("no byte header") unless bytes && bytes.length==2
      bytes = bytes.unpack('n').first
      return if @socket.closed?
      json  = @socket.read(bytes)
      raise IOError.new("not enough JSON data") unless json && json.length==bytes
      JSON.parse("[#{json}]",symbolize_names:true)[0]
    rescue JSON::ParserError => e
      warn "Failed to parse JSON response: #{json.inspect}; #{e}"
    rescue IOError => e
      @socket.close
    end
  end

  # Returns true if all data was sent, nil/false otherwise
  def send_data( data )
    json  = data.to_json
    bytes = json.length
    unless @socket.closed?
      @socket.write [bytes].pack('n')
      unless @socket.closed?
        @socket.write(json) == bytes
      end
    end
  end
  
  def closed?
    @socket.closed?
  end  
end
