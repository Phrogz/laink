#!/usr/bin/env ruby
#encoding: UTF-8

require_relative '../../client'
class DumpHigh < Laink::Client
	gametype 'com.danceliquid.domohnoes'
	attr_reader :name
	def initialize( name=nil )
		super()
		@name = name || self.class.name
	end
	def move( state )
		hand  = state[:hand ]
		board = state[:board]
		flat = board.flatten
		if board.empty?
			{ action:'play', domino:hand.max_by{ |d| d.inject(:+) } }
		elsif domino = hand.select{ |d| d.include?(flat.first) || d.include?(flat.last) }.max_by{ |d| d.inject(:+) }
			{ action:'play', domino:domino, edge:domino.include?(flat.first) ? 'left' : 'right' }
		else
			{ action:'chapped' }
		end
	end
	(ARGV[0] || 10).to_i.times{ self.new(ARGV[1]).play_game } if __FILE__==$0
end