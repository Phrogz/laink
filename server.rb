#!/usr/bin/env ruby
#encoding: UTF-8

require 'socket'
require 'json'

require_relative 'laink'

class LAINK::Server
	module PlayerLikeThing
		attr_accessor :game, :name, :thread
		def addy
			"'#{name}' (%s:%i)" % remote_address.ip_unpack
		end

		# Send a command to a client; wait for, get and decode the response
		def command( command, args={} )
			send_data command:command, args:args
			get_response
		end

		def send_data( data )
			message = data.to_json
			$stdout.puts "[#{Time.hms}] sending to #{addy}: '#{message}'" if $DEBUG
			send message, 0 #TODO: What flags?
		end

		def get_response
			begin
				response = recvfrom( LAINK::MAX_BYTES ).first   # FIXME: timeout
				begin
					response = JSON.parse_any(response,symbolize_names:true)
				rescue JSON::ParserError => e
					send_data error:"CommandParseError", details:{ text:request, error:e }
					warn "Failed to parse client response: #{response.inspect}; #{e}"
				end
				$stdout.puts "[#{Time.hms}] #{addy} sends #{response.inspect}" if $DEBUG
				response
			rescue Errno::ECONNRESET => e
				warn "Connection closed waiting for response"
			end
		end

		def your_turn
			state = game.state(self)
			begin
				move  = command( 'move', state:state )
				game.move_from( self, move )
			rescue Errno::ECONNRESET => e
				game.remove_player( self )
			end
		end

		def game_over
			send_data command:'gameover', winner:game.winner.name
		end

		def sleep
			Thread.stop
		end

		def awake
			thread.run
		end
	end

	DEFAULT_PORT = 54147
	def initialize( port=DEFAULT_PORT )
		server = TCPServer.new(port)
		puts "Starting #{self.class} on %s:%i" % server.local_address.ip_unpack
		@game_protector = Mutex.new
		@waiting_game_by_type = {}
		loop do
			Thread.start(server.accept) do |client|
				client.extend(PlayerLikeThing)
				client.thread = Thread.current
				begin
					puts "[#{Time.hms}] New connection from #{client.addy}"
					loop do
						request = client.get_response
						unless request && request[:command]
							warn "Disconnecting #{client.addy} due to malformed command #{request.inspect}"
							break
						end

						case request[:command]
							when 'gametype_supported?'								
								client.send_data LAINK::GameType.exists?( request[:args][:signature] )

							when 'game_active?'
								client.send_data client.game && client.game.active?

							when 'start_game'
								signature = request[:args][:signature]						
								unless gametype = LAINK::GameType[signature]
									client.send_data error:"UnsupportedGameType", details:{ gametype:signature }
								else
									client.name = request[:args][:name]
									waiting = create_or_join( gametype, client )
									client.sleep if waiting 
									break
								end
						end
					end
				ensure
					puts "Disconnecting client #{client.addy}"
					client.close
				end
			end
		end
	end

	def create_or_join( gametype, client )
		@game_protector.synchronize do
			game = (@waiting_game_by_type[gametype] ||= gametype.new)
			game << client
			if game.enough_players?
				@waiting_game_by_type[gametype] = nil
				game.start
				game.players.each do |player|
					player.send_data message:"Let's play some #{gametype.name}!"
					player.game = game
				end
				game.current_player.your_turn
				game.players.each(&:awake)
				false
			else
				true
			end
		end
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