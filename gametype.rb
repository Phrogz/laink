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
end