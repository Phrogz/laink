#encoding: UTF-8
require_relative 'laink'
require_relative 'server'

class LAINK::Player
	def initialize
		@server = nil
	end

	def self.gametype( signature=nil )
		signature ? @gametype = signature : @gametype
	end

	def name
		self.class.name
	end

	def connect( ip="localhost", port=LAINK::Server::DEFAULT_PORT )
		quit if connected?
		begin
			@server = TCPSocket.new( ip, port ) #FIXME: timeout
		rescue Errno::ECONNREFUSED => e
			puts "Count not connect to server."
			raise
		end
	end

	def connected?
		@server && !@server.closed?
	end

	def new_game( gametype=self.class.gametype )
		raise "Must specify a gametype for this player." unless gametype
		unless gametype_is_supported? gametype
			raise "The server at #{server_ip} does not support the gametype #{gametype}" 
		end

		# This will wait until all competitors have joined before returning
		server_command('start_game', signature:gametype, name:name )
		loop do
			message = get_from_server
			if message==nil
				puts "Uh..."
				next
			end
			case message[:command]
				when 'move'
					send_data(move(message[:args][:state]))
				when 'gameover'
					puts "Game was won by #{message[:winner]}"
					break
			end
		end
	end

	def gametype_is_supported?( gametype )
		server_command('gametype_supported?', signature:gametype)
	end

	def quit
		if connected?
			server_command 'goodbye'
			@server.close
		end
	end

	def server_ip
		@server && "%s:%i" % @server.remote_address.ip_unpack
	end

	# Send a command to the server, get and decode the response
	def server_command( command, args={} )
		send_data command:command, args:args
		response = get_from_server
		if response.is_a?(Hash) && response[:error]
			raise LAINK::Server.const_get(response[:error]).new( response[:details] )
		end
		response
	end

	def send_data( data )
		connect unless connected?
		message = data.to_json
		puts "[#{Time.hms}] Sending to server @ #{server_ip}: '#{message}'" if $DEBUG
		@server.send message, 0 #TODO: What flags?
	end

	def get_from_server
		connect unless connected?
		response = @server.recvfrom( LAINK::MAX_BYTES ).first   # FIXME: timeout
		begin
			response = JSON.parse_any(response,symbolize_names:true)
		rescue JSON::ParserError => e
			raise "Failed to parse server response: #{response.inspect}; #{e}"
		end
		puts "[#{Time.hms}] Server @ #{server_ip} sends #{response.inspect}" if $DEBUG
		response
	end

end
