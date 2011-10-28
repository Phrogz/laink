#encoding: UTF-8
require_relative 'json_socket'
require_relative 'laink'
class Laink::Client
	##########################################
	### DSL for classes to describe themselves
	##########################################
	def self.gametype( signature=nil )
		signature ? @gametype = signature : @gametype
	end

	def initialize
		@server = nil
	end

	def name
		# Override in subclass to have a nice name
		self.class.name
	end

	def play_game( gametype=self.class.gametype )
		raise "Must specify a gametype for this player." unless gametype
		connect unless connected?
		@server.command 'start_game', gametype:gametype, nick:name
		@server.on_receive do |message|
			case message[:command]
				when 'move'
					@server.command( 'move', move(message[:state]) )
				when 'gameover'
					p [ message[:winner], name ]
					puts "Game was won by #{message[:winner]} (#{message[:winner]==name ? "That's me!" : "not me"})"
					throw( :no_more_messages, message[:winner]==name )
			end
		end
	end

	def connect( ip="localhost", port=Laink::DEFAULT_PORT )
		disconnect if connected?
		begin
			socket = TCPSocket.new( ip, port ) #FIXME: timeout
			@server = Laink::JSONSocket.new( socket )
		rescue Errno::ECONNREFUSED => e
			warn "Could not connect to #{ip}:#{port}."
			raise
		end
	end

	def connected?
		@server && !@server.closed?
	end

	def disconnect
		@server.close
		@server = nil
	end

	# TODO: requires a Thread for asynchronous sending that I don't care to do now.
	# def quit
	# 	if connected?
	# 		@server.command 'quit'
	# 		@server.close
	# 	end
	# end
end
