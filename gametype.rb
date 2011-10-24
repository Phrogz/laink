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
		@active  = false
		@players = []
	end

	def start
		@active = true
	end

	def active?
		@active
	end

	def finish_game( winner=nil )
		@active = false
		@winner = winner
	end

	def add_player( player )
		@players << player
		raise "Too many players" if too_many_players?
	end
	alias_method :<<, :add_player

	def enough_players?( player_count=@players.length )
		self.class.players.include?( player_count )
	end

	def too_few_players?( player_count=@players.length )
		player_count < self.class.players.first
	end

	def too_many_players?( player_count=@players.length )
		player_count > self.class.players.first
	end
end