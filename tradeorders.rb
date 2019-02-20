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
browser.input(name: 'Login').click

browser.goto(tradeurl)
browser.text_field(name: 'batch_source_name').set("ibbot #{Time.now}")
browser.select_list(name: "batch_account_uid").options.find do |option|
  option.text.include? pfname
end.select
browser.select_list(name: "batch_order_type_uid").select("Limit")
browser.textarea(name: "batch_txt").set(ordertxt)
browser.link(text: "Add to Order").click
browser.link(text: "Review and Submit").click
browser.link(text: "Send Order").click








