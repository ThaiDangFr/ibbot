#!/usr/bin/env ruby
# ruby.bastardsbook.com/chapters/mechanize/

require 'mechanize'
require 'logger'
require 'json'
require 'fileutils'
require 'iex-ruby-client'

ticker=ARGV[0]

if ticker.nil?
  raise "Syntax : #{__FILE__} <ticker>"
end

quote = IEX::Resources::Quote.get(ticker)
pp quote.latest_price


