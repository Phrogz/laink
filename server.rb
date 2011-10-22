#!/usr/bin/env ruby
#encoding: UTF-8

require 'socket'
require 'json'

require_relative 'laink'

class LAINK::Server
	DEFAULT_PORT = 54147
	def initialize( port=DEFAULT_PORT )
		server = TCPServer.new(port)
		puts "Starting #{self.class} on %s:%i" % server.local_address.ip_unpack
		$stdout.flush
		loop do
			Thread.start(server.accept) do |client|
				begin
					puts "New connection from %s:%i" % client.remote_address.ip_unpack
					$stdout.flush
					loop do
						request = client.recvfrom(LAINK::MAX_BYTES).first # FIXME: timeout
						p [:client_request,request] if $DEBUG
						request = JSON.parse( request ) 
						p [:client_request_parsed,request] if $DEBUG
						case request['command']
							when 'gametype_supported'
								respond_to client, { result: LAINK::GameType.exists?( request['args'].first ) }
							when 'start_game'
								signature = request['args'].first								
								unless gametype = LAINK::GameType[signature]
									respond_to client, { error:"unsupported game type #{signature.inspect}" }
								else
									@game = gametype.new
									respond_to client, { message:"Let's play some #{gametype.name}!" }
								end

							when 'goodbye'
								@game = nil
								respond_to client, { message:"Goodbye, friend!" }
								break
						end
					end
				ensure
					puts "Disconnecting client from %s:%i" % client.remote_address.ip_unpack 
					client.close
				end
			end
		end
	end

	def respond_to( client, data )
		response = data.to_json
		p [:response, response] if $DEBUG
		client.send response, 0 #TODO: What flags?
	end

end


if __FILE__==$0
	Dir['gametypes/*.rb'].each{ |rb| require_relative rb }
	p LAINK::GameType.instance_eval{ @by_signature }

	LAINK::Server.new 
end