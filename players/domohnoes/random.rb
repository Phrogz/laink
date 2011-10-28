#!/usr/bin/env ruby
#encoding: UTF-8

require_relative '../../client'
class RandomMatch < Laink::Client
	gametype 'com.danceliquid.domohnoes'
	attr_reader :name
	def initialize( name=nil )
		super()
		@name = name || self.class.name
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
	1000.times{ RandomMatch.new(ARGV[0]).play_game }
end