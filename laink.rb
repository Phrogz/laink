#encoding: UTF-8
require 'socket'
require 'json'

module LAINK
	MAX_BYTES = 2**16-1
end

# Work around a flaw in Ruby's built-in JSON parser
# not accepting anything but an object or array at the root level.
module JSON
	def self.parse_any(str,opts={})
		parse("[#{str}]",opts).first
	end
end
