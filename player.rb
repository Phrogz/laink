#encoding: UTF-8
require_relative 'laink'
require_relative 'server'

class LAINK::Player
	def self.gametype( signature=nil )
		signature ? @gametype = signature : @gametype
	end

	def connect( ip="localhost", port=LAINK::Server::DEFAULT_PORT )
		quit if connected?
		@server = TCPSocket.new( ip, port ) #FIXME: timeout
	end

	def connected?
		@server && !@server.closed?
	end

	def new_game( gametype=self.class.gametype )
		raise "Must specify a gametype for this player." unless gametype
		unless gametype_is_supported? gametype
			raise "The server at #{server_ip} does not support the gametype #{gametype}" 
		end
		server_command 'start_game', gametype
	end

	def gametype_is_supported?( gametype )
		server_command('gametype_supported', gametype)['result']
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
	def server_command( command, *args )
		connect unless connected?
		@server.send( {command:command, args:args}.to_json, 0 ) # TODO: What flags are appropriate here?
		response = @server.recvfrom( LAINK::MAX_BYTES ).first   # FIXME: timeout
		p [:server_response,response] if $DEBUG
		response = JSON.parse(response)
		p [:server_response_parsed,response] if $DEBUG
		response
	end

end
