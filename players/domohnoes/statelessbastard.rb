#!/usr/bin/env ruby
#encoding: UTF-8

require_relative '../../client'
class StatelessBastard < Laink::Client
	gametype 'com.danceliquid.domohnoes'
	def move( state )
		hand  = state[:hand ]
		board = state[:board]
		
		have = Hash[ hand.flatten.group_by(&:to_i).map{ |i,a| [i,a.length] } ]
		have.default = 0
		desc = hand.sort_by{ |d| -d.inject(:+) }

		if board.empty?
			# Play biggest pips that I also have another one of
			biggest = desc.find{ |d| have[d[0]] > 1 || have[d[1]] > 1 }
			{ action:'play', domino:biggest }
		else
			valid = hand.select{ |d| edge(d,board) }
			if valid.empty?
				{ action:'chapped' }
			else
				seen = Hash[ board.flatten.group_by(&:to_i).map{ |i,a| [i,a.length] }.sort_by{ |i,c| -c } ]
				seen.default = 0
				play = valid.map{ |d|
					{left:board.first.first, right:board.last.last}.map do |edge,connector|
						double  = d.first==d.last
						exposed = d - [connector]
						if exposed.length!=2
							exposed = double ? connector : exposed.first
							{edge:edge, domino:d, have:have[exposed] - (double ? 2 : 1), seen:seen[exposed] }
						end
					end.compact
				}.flatten.max_by{ |play|
					[ play[:seen], play[:domino].inject(:+) ]
					#[ play[:seen], play[:have] ]
				}
				{ action:'play' }.merge(play)
			end
		end
	end
	def edge(domino,board)
		if domino.include?(board.first.first)
			"left"
		elsif domino.include?(board.last.last)
			"right"
		end
	end
	self_run if __FILE__==$0
end