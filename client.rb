#encoding: UTF-8
require_relative 'json_socket'
require_relative 'laink'
class Laink::Client
	##########################################
	### DSL for classes to describe themselves
	##########################################
	def self.gametype( gametype=nil )
		gametype ? @gametype = gametype : @gametype
	end

	attr_accessor :min_players, :rounds, :name
	def initialize
		@server      = nil
		@min_players = 2
		@rounds      = 1
		@name        = self.class.name
	end

	def start_game
	end

	def play_game( gametype=self.class.gametype )
		raise "Must specify a gametype for this player." unless gametype
		connect unless connected?
		@server.command 'start_game', gametype:gametype, nick:name, min_players:min_players, rounds:rounds
		@server.on_receive do |message|
			case message[:command]
				when 'move'
					@server.command( 'move', move(message[:state]) )
				when 'new_game'
					puts "Game on!" if $DEBUG
					start_game
				when 'gameover'
					puts "Game was won by #{message[:winner]} (#{message[:winner]==name ? "That's me!" : "not me"})"
				when 'goodbye'
					puts "Final score: #{message[:scores].inspect}"
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

	def valid_move?(proposed)
		@server.command 'valid_move?', proposed
		@server.read_data
	end

	def self.self_run
		iterations  = (ARGV[0] || 10).to_i
		min_players = (ARGV[1] ||  2).to_i
		name        = ARGV[2]

		player             = self.new
		player.rounds      = iterations
		player.min_players = min_players
		player.name        = name if name
		player.play_game
	end

	# TODO: requires a Thread for asynchronous sending that I don't care to do now.
	# def quit
	# 	if connected?
	# 		@server.command 'quit'
	# 		@server.close
	# 	end
	# end
end
