#!/usr/bin/env ruby
# prerequisite : 
# yum install chromedriver
# yum install google-chrome-stable


require 'watir'
require 'logger'
require 'json'
require 'fileutils'
require 'iex-ruby-client'

pfname = ARGV[0]
orderfile = ARGV[1]

if pfname.nil? or orderfile.nil?
  raise "Syntax : #{__FILE__} <portfolio name> <order file>"
end


loginurl = "https://www.portfolio123.com/login.jsp?url=%2F"
tradeurl = "https://www.portfolio123.com/app/trade/orderBatch"
username = ENV['P123USR']
password = ENV['P123PWD']
outputdir = "output"


ordertxt = File.read(orderfile)

browser = Watir::Browser.new
browser.goto(loginurl)
browser.input(name: 'LoginUsername').send_keys(username)
browser.input(name: 'LoginPassword').send_keys(password)
browser.input(values: 'Submit').click












