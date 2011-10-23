#encoding: UTF-8
require_relative '../gametype'

class Domohnoes < LAINK::GameType
	sig     "com.danceliquid.domohnoes"
	name    "Domohnoes"
	players 2
	def initialize()
		super()
	end
	def state
		{ cats:"in cradle", silver_spoon:true }
	end
	def valid_move?( move )
		false
	end
end
