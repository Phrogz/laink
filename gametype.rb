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

	attr_reader :players
	def initialize
		@active  = false
		@players = []
	end

	def active?
		@active
	end

	def finish_game
		@active = false
	end

	def add_player( player )
		allowed = self.class.players
		@players << player
		case allowed <=> @players.length
			when -1 then @active = false
			when  0 then @active = true
			when  1 then
				@active = false
				raise "Too many players"
		end
	end
	alias_method :<<, :add_player

	def enough_players?( player_count=@players.length )
		self.class.players.include?( player_count )
	end


end