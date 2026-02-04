#!/usr/bin/env ruby
require_relative 'config/environment'

# Simple debug script to test the sign in page
require 'net/http'
require 'uri'

uri = URI('http://localhost:3000/users/sign_in')
response = Net::HTTP.get_response(uri)

puts "Status: #{response.code}"
puts "Headers:"
response.each_header { |key, value| puts "  #{key}: #{value}" }
puts "\nBody (first 500 chars):"
puts response.body[0..500]
