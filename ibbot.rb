#!/usr/bin/env ruby

require 'mechanize'
require 'logger'

p123id=ARGV[0]

if p123id.nil?
  raise "Syntax : #{__FILE__} <portfolio id>"
end


loginurl = "https://www.portfolio123.com/login.jsp?url=%2F"
pfurl = "https://www.portfolio123.com/p123/DownloadPortHoldings?portid=#{p123id}"
username = ENV['P123USR']
password = ENV['P123PWD']

agent = Mechanize.new
agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
agent.user_agent_alias = 'Linux Firefox'
#agent.log = Logger.new(STDOUT)
page = agent.get(loginurl)
form = page.forms.first


form["LoginUsername"] = username
form["LoginPassword"] = password
form["url"] = "/"
agent.submit(form, form.buttons.first)
page = agent.get(pfurl)

pp page.content.split("\n")



