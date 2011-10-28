#encoding: UTF-8
require 'json'
require 'socket'
require_relative 'laink'

class Laink::JSONSocket
	attr_reader :socket, :address
	def initialize( socket )
		@socket  = socket
		@address = if @socket.respond_to? :remote_address
			"%s:%i" % @socket.remote_address.ip_unpack
		else
			"(No Address on 1.9.1-)"
		end
	end

	def command( type, details={} )
		send_data( {command:type}.merge(details) )
	end

	def error( message, details={} )
		send_data( {error:message}.merge(details) )
	end

	def on_receive
		catch(:no_more_messages) do
			while message = read_data
				yield(message)			
			end
		end
	end

	# Returns true if all data was sent, nil/false otherwise
	def send_data( data )
		json  = data.to_json
		bytes = json.bytesize
		puts "SEND %3i bytes   to %s: %s" % [bytes,@address,json] if $DEBUG
		unless @socket.closed?
			@socket.write [bytes].pack('n')
			unless @socket.closed?
				@socket.write(json) == bytes
			end
		end
	end

	# Returns nil for a closed connection
	def read_data
		begin
			return if @socket.closed?
			bytes = @socket.read(2)
			raise IOError.new("no byte header") unless bytes && bytes.bytesize==2
			bytes = bytes.unpack('n').first
			return if @socket.closed?
			json  = @socket.read(bytes)
			puts "RECV %3i bytes from %s: %s" % [bytes,@address,json] if $DEBUG
			raise IOError.new("not enough JSON data") unless json && json.bytesize==bytes
			JSON.parse("[#{json}]",symbolize_names:true)[0]
		rescue JSON::ParserError => e
			warn "Failed to parse JSON response: #{json.inspect}; #{e}"
		rescue IOError => e
			@socket.close
		end
	end

	def method_missing(*a,&b)
		@socket.__send__(*a,&b)
	end
end
