#!/usr/bin/env ruby
#encoding: UTF-8

require_relative 'player'
class Dominaster < LAINK::Player
	gametype 'com.danceliquid.domohnoes'
	def name
		"#{self.class.name}_#{object_id.to_s(36)}"
	end
	def move( state )
		hand  = state[:hand].shuffle
		board = state[:board]
		flat = board.flatten
		if board.empty?
			{action:'play', domino:hand.first }
		elsif domino = hand.find{ |d| d.include?(flat.first) }
			{action:'play', domino:domino, edge:'left'}
		elsif domino = hand.find{ |d| d.include?(flat.last) }
			{action:'play', domino:domino, edge:'right'}
		else
			{action:'chapped'}
		end
	end
end

if __FILE__==$0
	player = Dominaster.new
	player.connect
	player.new_game
end