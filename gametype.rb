#encoding: UTF-8
require_relative 'laink'

class LAINK::GameType
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
	def self.name( name=nil )
		name ? (@name ||= name) : @name
	end
	def self.sig( sig=nil )			
		@sig ||= sig if sig
		LAINK::GameType[@sig] = self
	end
	def self.players( players=nil )
		if players
			@players = players.is_a?(Range) ? players : players..players
		else
			@players
		end
	end

	attr_reader :players, :winner
	def initialize
		@started  = false
		@finished = false
		@players = []
	end

	def start
		@started = true
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
		@winner = winner
	end

	def add_player( player )
		@players << player
		raise "Too many players" if too_many_players?
	end
	alias_method :<<, :add_player

	def remove_player( player )
		@players.delete( player )
		player.thread.run
		unless enough_players?
			raise "Game cannot continue; not enough players"
		end
	end

	def enough_players?( player_count=@players.length )
		self.class.players.include?( player_count )
	end

	def too_few_players?( player_count=@players.length )
		player_count < self.class.players.first
	end

	def too_many_players?( player_count=@players.length )
		player_count > self.class.players.first
	end

	def move_from
		if active?
			current_player.your_turn
		else
			players.each(&:game_over)
		end
	end
end