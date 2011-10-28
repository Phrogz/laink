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
	(ARGV[0] || 10).to_i.times{ self.new(ARGV[1]).play_game } if __FILE__==$0
end


