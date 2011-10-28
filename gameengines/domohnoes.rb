#encoding: UTF-8
require_relative '../gameengine'

class Domohnoes < Laink::GameEngine
	gametype "com.danceliquid.domohnoes"
	name     "Domohnoes"
	players  2..4

	LEFT_EDGE  = /\A(?:left|start|front|first)\z/
	RIGHT_EDGE = /\A(?:right|end|back|last)\z/

	def initialize(max=6)
		super()
		@max = max
		@board = []
		@player_index = 0
		@sequential_chaps = 0
	end

	def start
		dominoes = 0.upto(@max).map{ |top| top.upto(@max).map{ |bottom| [top,bottom] } }.flatten(1).shuffle
		@dominoes_by_player = Hash[ players.map{ |player| [ player, dominoes.pop(7) ] } ]
		super()
	end

	def finish_game
		unless winner = players.find{ |player| hand(player).empty? }
			winners = players.group_by{ |player| hand(player).flatten.inject(:+) }.min_by(&:first).last
			winner  = winners.first if winners.length==1
		end
		super(winner)
	end

	def current_player
		players[@player_index]
	end

	def state( player )
		{ hand:hand(player), board:@board }
	end

	def handle_message( message, player )
		case message[:command]
			when 'move'
				if player==current_player
					if valid_move?( message, player )
						process_move( message, player )
					else
						player.error 'InvalidMove', move:message
					end
				end
				true
			else
				super
		end
	end

	def valid_move?( move, player )
		puts "Validating #{move.inspect} for #{player.nick} vs. #{current_player.nick} @ #{@board.inspect}" if $DEBUG
		case move[:action]
			when 'chapped'
				return false if @board.empty?
				!hand( player ).any?{ |domino| domino_goes_on_board?(domino,'left') || domino_goes_on_board?(domino,'right') }
			when 'play'
				domino = move[:domino].sort
				return false unless domino.length==2
				return false unless hand( player ).include?( domino )
				@board.empty? || domino_goes_on_board?( domino, move[:edge] )
		end
	end

	def domino_goes_on_board?( domino, board_side )
		case board_side
			when LEFT_EDGE  then domino.include?( @board.first.first )
			when RIGHT_EDGE then domino.include?( @board.last.last   )
		end
	end

	def process_move( move, player )
		raise "not your move" unless player == current_player
		raise "invalid move"  unless valid_move?( move, player )
		case move[:action]
			when 'chapped'
				finish_game if (@sequential_chaps += 1) == players.length

			when 'play'
				@sequential_chaps = 0
				flat = @board.flatten
				domino = move[:domino].sort
				hand( player ).delete( domino )
				case move[:edge]
					when LEFT_EDGE
						@board.unshift( flat.first==domino.last ? domino : domino.reverse )
					else # Handles no edge initial move as well as explicit right edge
						@board.push(    flat.last==domino.first ? domino : domino.reverse )
				end
				finish_game if hand( player ).empty?

		end
		@player_index = ( @player_index + 1 ) % players.length
	end

	private
		def hand( player )
			@dominoes_by_player[player]
		end
end
