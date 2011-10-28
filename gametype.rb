#encoding: UTF-8
require_relative 'laink'
class Laink::GameType
	##############################
	### Tracking registered types
	##############################
	@by_signature = {}
	def self.[](signature)
		@by_signature[signature]
	end
	def self.[]=(signature, gametype)
		@by_signature[signature] = gametype
	end
	def self.known
		@by_signature.values.sort
	end
	def self.exists?(signature)
		@by_signature.key?(signature)
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
	def self.sig( sig=nil )			
		@sig ||= sig if sig
		Laink::GameType[@sig] = self
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
		@started  = false
		@finished = false
		@players  = []
		@message_lock = Mutex.new
		@player_messages = {}
		@processor = nil
	end

	def start
		@started = true
		@processor = Thread.new do
			until finished?
				player = current_player
				player.your_turn
				while @message_lock.synchronize{ @player_messages[player].empty? } # TODO: timeout
					Thread.stop
					# We'll get woken up by #message_from
				end
				:go while handle_message_from( player )
			end
			players.each(&:game_over)
			@processor = nil
		end
	end

	# Should be overridden by subclasses with super(); this only handles common commands
	# Returns nil for a message not ready to be handled
	def handle_message_from( player )
		# TODO: What other commands might we support?
		if next_message(player){ |m| m[:command]=='quit' }
			remove_player(player)
		end
	end

	def next_message( player )
		@message_lock.synchronize do
			queue = @player_messages[player] ||= []
			if message = queue.first
				block_given? ? yield(message) && queue.shift : queue.shift
			end
		end
	end

	def message_from( player, message )
		@message_lock.synchronize{ (@player_messages[player] ||= []) << message }
		@processor.run if @processor
	end

	def started?
		@started
	end

	def active?
		started? && !finished?
	end

	def finished?
		@finished
	end

	def finish_game( winner=nil )
		@finished = true		
		if @winner = winner
			record = self.class.record_win(winner, players)
			puts "#{self.class} records: #{Hash[ record.sort_by{ |nick,wins| [-wins,nick] } ]}"
		end
	end

	def <<( player )
		players << player
		@player_messages[player] = []
		raise "Too many players" if too_many_players?
	end

	def remove_player( player )
		players.delete( player )
		@player_messages[player] = nil
		raise "Game cannot continue; not enough players" unless enough_players?
	end

	def enough_players?( player_count=players.length )
		self.class.players.include?( player_count )
	end

	def too_few_players?( player_count=players.length )
		player_count < self.class.players.first
	end

	def too_many_players?( player_count=players.length )
		player_count > self.class.players.first
	end

	def accepting_players?
		!started?
	end
end