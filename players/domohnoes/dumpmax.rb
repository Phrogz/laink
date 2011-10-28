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
		else
			if domino = hand.select{ |d| d.include?(flat.first) || d.include?(flat.last) }.max_by{ |d| d.inject(:+) }
				if domino.include?(flat.first)
					{action:'play', domino:domino, edge:'left' }
				else
					{action:'play', domino:domino, edge:'right'}
				end
			else
				{action:'chapped'}
			end
		end
	end
end

if __FILE__==$0
	1000.times{ DumpHigh.new(ARGV[0]).play_game }
end