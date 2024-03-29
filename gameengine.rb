#encoding: UTF-8
require_relative 'laink'
require 'thread'
class Laink::GameEngine
	##############################
	### Tracking registered types
	##############################
	@engines_by_type = {}
	def self.[](gametype)
		@engines_by_type[gametype]
	end
	def self.[]=(gametype, engine)
		@engines_by_type[gametype] = engine
	end
	def self.known
		@engines_by_type.values.sort
	end
	def self.exists?(gametype)
		@engines_by_type.key?(gametype)
	end

	##############################
	### Tracking player statistics
	##############################
	def self.records(players)
		(@stats ||= {})[players.map(&:nick).sort] ||= Hash[ players.map(&:nick).zip([0]*players.length) ]
	end
	def self.record_win(winner, players)
		records(players).tap do |record|
			record[winner.nick] += 1
		end
	end

	##########################################
	### DSL for classes to describe themselves
	##########################################
	def self.name( name=nil )
		name ? (@name ||= name) : @name
	end
	def self.gametype( gametype=nil )
		@gametype ||= gametype if gametype
		Laink::GameEngine[@gametype] = self
		@gametype
	end
	def self.players( players=nil )
		if players
			@players = players.is_a?(Range) ? players : players..players
		else
			@players
		end
	end

	##########################################
	### Base implementation
	##########################################
	attr_reader :players, :winner
	def initialize
		@players  = []
		@processor = nil
		@player_messages = {}
		reset_game
	end

	def reset_game
		@started  = false
		@finished = false
		@player_messages.map(&:last).each(&:clear)
	end

	def start(games=1)
		@started = true
		@processor = Thread.new do
			print "Playing #{games} games of #{self.class.gametype}: "
			$stdout.flush
			games.times do
				reset_game
				players.each(&:new_game)
				last_player = nil
				turn = 0
				until game_over?
					puts "### Turn ##{turn += 1} #########################" if $DEBUG
					player = current_player
					queue  = @player_messages[player]
					player.your_turn
					until current_player != player || game_over?
						next_message = queue.shift
						unless handle_message( next_message, player )
							player.error "UnhandledMessage", message:next_message
						end
					end
				end
				players.each(&:game_over)
				print "."
				$stdout.flush
			end
			players.each(&:goodbye)
			write_standings
			@processor = nil
		end
	end

	def write_standings
		require 'time' # for iso8601
		Dir.mkdir('standings') unless File.exists?('standings')
		File.open(File.join('standings',self.class.gametype),'a') do |f|
			standing = self.class.records(players)
			message = "#{Time.now.gmtime.iso8601} #{Hash[ standing.sort_by{ |nick,wins| [-wins,nick] } ]}"
			puts message
			$stdout.flush
			f.puts message
		end
	end

	# Should be overridden by subclasses with super(); this only handles common commands
	# Returns nil for a message not ready to be handled
	def handle_message( message, player )
		case message[:command]
			when 'state'       then player.send_data state:state(player)
			when 'players'     then player.send_data players.map(&:nick)
			when 'valid_move?' then player.send_data valid_move?( message, player )
			when 'quit'        then remove_player(player)
			else return
		end
		true
	end

	def message_from( player, message )
		@player_messages[player] << message
	end

	def started?
		@started
	end

	def active?
		started? && !game_over?
	end

	def game_over?
		@finished
	end

	def finish_game( winner=nil )
		@finished = true		
		self.class.record_win(winner, players) if @winner = winner
	end

	def <<( player )
		players << player
		@player_messages[player] = Queue.new
		raise "Too many players" if too_many_players?
	end

	def remove_player( player )
		players.delete( player )
		@player_messages[player] = nil
		raise "Game cannot continue; not enough players" unless enough_players?
		true
	end

	def enough_players?( player_count=players.length )
		self.class.players.include?( player_count )
	end

	def too_few_players?( player_count=players.length )
		player_count < self.class.players.first
	end

	def too_many_players?( player_count=players.length )
		player_count > self.class.players.last
	end

	def accepting_players?
		!started?
	end
end