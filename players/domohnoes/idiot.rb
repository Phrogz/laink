#!/usr/bin/env ruby
#encoding: UTF-8

require_relative '../../client'
class Idiot < Laink::Client
	gametype 'com.danceliquid.domohnoes'
	attr_reader :name
	def initialize( name=nil )
		super()
		@name = name || self.class.name
	end
	def move( state )
		hand = state[:hand]
		hand.sort.each{ |domino|
			move = { action:'play', domino:domino, edge:'left' }
			return move if valid_move?(move)
			move[:edge]='right'
			return move if valid_move?(move)
		}
		{ action:'chapped' }
	end
	(ARGV[0] || 10).to_i.times{ self.new(ARGV[1]).play_game } if __FILE__==$0
end