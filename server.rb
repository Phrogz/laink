#!/usr/bin/env ruby
#encoding: UTF-8

require 'socket'
require 'json'

require_relative 'laink'

class LAINK::Server
	module SocketsArePlayers
		attr_accessor :game, :name
	end

	DEFAULT_PORT = 54147
	def initialize( port=DEFAULT_PORT )
		server = TCPServer.new(port)
		puts "Starting #{self.class} on %s:%i" % server.local_address.ip_unpack
		@game_protector = Mutex.new
		@waiting_game_by_type = {}
		loop do
			Thread.start(server.accept) do |client|
				client.extend(SocketsArePlayers)
				begin
					client_address = "%s:%i" % client.remote_address.ip_unpack
					puts "New connection from #{client_address}"
					loop do
						request_json = client.recvfrom(LAINK::MAX_BYTES).first # FIXME: timeout
						begin
							request = JSON.parse_any(request_json,symbolize_names:true) 
						rescue JSON::ParserError => e
							respond_to client, { error:"CommandParseError", details:{ text:request, error:e } }
							next
						end
						puts "Received: #{request.inspect}" if $DEBUG

						unless request && request[:command]
							warn "Disconnecting #{client_address} due to malformed command #{request_json.inspect}"
							break
						end

						case request[:command]
							when 'identify'
								client.name = request[:args][:name]
								respond_to client, "Hello, #{client.name}"

							when 'gametype_supported?'								
								respond_to client, LAINK::GameType.exists?( request[:args][:signature] )

							when 'game_active?'
								respond_to client, client.game && client.game.active?

							when 'start_game'
								signature = request[:args][:signature]						
								unless gametype = LAINK::GameType[signature]
									respond_to client, { error:"UnsupportedGameType", details:{ gametype:signature } }
								else
									create_game( gametype, client )
								end

							when 'current_state'
								respond_to( client, error:"NoActiveGame" ) && next unless client.game
								respond_to( client, error:"GameIsOver"   ) && next unless client.game.active?
								respond_to( client, client.game.state    )

							when 'move'
								respond_to( client, error:"NoActiveGame" ) && next unless client.game
								respond_to( client, error:"GameIsOver"   ) && next unless client.game.active?
								respond_to( client, error:"InvalidMove"  ) && next unless client.game.valid_move?( request[:move] )
								# TODO: ask the game to tell me when it's my turn...or something
								respond_to( client, { state:game.state } )

							when 'goodbye'
								client.game = nil
								respond_to client, { message:"Goodbye, friend!" }
								break
						end
					end
				ensure
					puts "Disconnecting client from #{client_address}"
					client.close
				end
			end
		end
	end

	def create_game( gametype, client )
		@game_protector.synchronize do
			game = (@waiting_game_by_type[gametype] ||= gametype.new)
			game << client
			if game.enough_players?
				game.players.each do |player|
					respond_to player, { message:"Let's play some #{gametype.name}!" }
					player.game = game
				end
				@waiting_game_by_type[gametype] = nil
			end
		end
	end

	def respond_to( client, data )
		response = data.to_json
		puts "Sending: '#{response}'" if $DEBUG
		client.send response, 0 #TODO: What flags?
	end

end

# Create Error constants for each type of error (so that Ruby clients can rescue specific ones)
%w[ CommandParseError UnsupportedGameType NoActiveGame GameIsOver InvalidMove ].each do |name|
	error = Class.new(RuntimeError) do
		attr_reader :details
		def initialize(details)
			@details = details
			super(details.inspect)
		end
	end
	LAINK::Server.const_set(name,error)
end

if __FILE__==$0
	Dir['gametypes/*.rb'].each{ |rb| require_relative rb }
	puts "Loaded games: #{LAINK::GameType.known}"
	LAINK::Server.new 
end