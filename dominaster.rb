#!/usr/bin/env ruby
#encoding: UTF-8

require_relative 'player'
class Dominaster < LAINK::Player
	gametype 'com.danceliquid.domohnoes'
end

if __FILE__==$0
	player = Dominaster.new
	player.connect
	player.new_game
	player.quit
end