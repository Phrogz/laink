#!/usr/bin/env ruby
#encoding: UTF-8

require_relative '../../client'
class StatelessBastard < Laink::Client
	gametype 'com.danceliquid.domohnoes'
	def move( state )
		hand  = state[:hand ]
		board = state[:board]
		
		have = Hash[ hand.flatten.group_by(&:to_i).map{ |i,a| [i,a.length] } ]
		desc = hand.sort_by{ |d| -d.inject(:+) }

		if board.empty?
			# Play biggest pips that I also have another one of
			biggest = desc.find{ |d| have[d[0]] > 1 || have[d[1]] > 1 }
			{ action:'play', domino:biggest }
		else
			valid = hand.select{ |d| d.include?(flat.first) || d.include?(flat.last) })
			if valid.empty?
				{ action:'chapped' }
			else
				seen = Hash[ board.flatten.group_by(&:to_i).map{ |i,a| [i,a.length] }.sort_by{ |i,c| -c } ]
				domino = seen.find{ |d| have}

				{ action:'play', domino:domino, edge:domino.include?(flat.first) ? 'left' : 'right' }
			end
		end
	end
	self_run if __FILE__==$0
end