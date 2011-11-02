#!/usr/bin/env ruby
#encoding: UTF-8
require_relative 'laink'
require_relative 'json_socket'

class Laink::JSONSocket::Player < Laink::JSONSocket
	attr_accessor :nick, :game
	alias_method :name, :nick
	def your_turn
		command 'move', state:game.state(self)
	end
	def game_over
		command 'gameover', winner:(game.winner && game.winner.nick)
	end
	def goodbye
		command 'goodbye', scores:game.class.records(game.players)
	end
	def new_game
		command 'new_game'
	end
end

class Laink::Server
	DEFAULT_PORT = 54147
	def initialize( port=DEFAULT_PORT )
		@idle_game_by_engine_and_players = {}
		@game_protector = Mutex.new
		listen_for_clients(port)
	end
	
	def listen_for_clients(port)
		server = TCPServer.new(port)
		loop do
			# Create a new reader thread for each socket that connects
			Thread.start(server.accept) do |socket|
				client = Laink::JSONSocket::Player.new(socket)
				begin
					message = client.read_data
					if message[:command]=='start_game' && message[:nick]
						client.nick = message[:nick]
						if engine = Laink::GameEngine[ message[:gametype] ]
							if game = create_game(engine,client,message[:min_players],message[:rounds])
								client.game = game
								client.on_receive{ |command| game.message_from(client,command) }
							else
								client.error "CouldNotCreateGame" # Should never occur?
							end
						else
							client.error "UnsupportedGameType", gametype:message[:gametype]
						end
					else
						client.error "OutOfOrderCommand", details:'Clients must send {"command":"start_game", "nick":"foo", "gametype":"bar"} before anything else.'
					end
				ensure
					client.close unless client.closed?
				end
			end
		end
	end

	def create_game(engine,player,players=2,rounds=1)
		@game_protector.synchronize do
			(@idle_game_by_engine_and_players[[engine,players]] ||= engine.new).tap do |game|
				game << player
				game.start(rounds) if game.players.length >= players
				@idle_game_by_engine_and_players[[engine,players]] = nil unless game.accepting_players?
			end
		end
	end

	# Create Error constants for each type of error (so that Ruby clients can rescue specific ones)
	%w[ CommandParseError CouldNotCreateGame UnsupportedGameType NoActiveGame GameIsOver InvalidMove ].each do |name|
		const_set( name, Class.new(RuntimeError) do
			attr_reader :details
			def initialize(details)
				@details = details
				super(details.inspect)
			end
		end )
	end
end

if __FILE__==$0
	Dir['gameengines/*.rb'].each{ |rb| require_relative rb }
	puts "Loaded games: #{Laink::GameEngine.known}"
	Laink::Server.new 
end