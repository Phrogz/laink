#encoding: UTF-8
require_relative 'laink'
require_relative 'server'

class LAINK::Player
	def self.gametype( signature=nil )
		signature ? @gametype = signature : @gametype
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
		server_command('start_game', signature:gametype)

		while server_command 'game_active?'
			state   = server_command 'current_state'
			my_move = move( state )
			server_command 'move', {move:my_move} # TODO: authenticating...anything? Maybe sockets + threads ensures that I'm the only possible player sending this?
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
		connect unless connected?
		@server.send( {command:command, args:args}.to_json, 0 ) # TODO: What flags are appropriate here?
		response = @server.recvfrom( LAINK::MAX_BYTES ).first   # FIXME: timeout
		begin
			response = JSON.parse_any(response,symbolize_names:true)
		rescue JSON::ParserError => e
			raise "Failed to parse server response: #{response.inspect}; #{e}"
		end
		p "Server response: #{response.inspect}" if $DEBUG
		
		if response.is_a?(Hash) && response[:error]
			raise LAINK::Server.const_get(response[:error]).new( response[:details] )
		end
		response
	end

end
