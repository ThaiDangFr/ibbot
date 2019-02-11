#!/usr/bin/env ruby
# ruby.bastardsbook.com/chapters/mechanize/

require 'mechanize'
require 'logger'
require 'json'
require 'fileutils'

p123id=ARGV[0]

if p123id.nil?
  raise "Syntax : #{__FILE__} <portfolio id>"
end


loginurl = "https://www.portfolio123.com/login.jsp?url=%2F"
pfurl = "https://www.portfolio123.com/p123/DownloadPortHoldings?portid=#{p123id}"
username = ENV['P123USR']
password = ENV['P123PWD']
outputdir = "output"

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

array = page.content.split("\n").map { |x| x.chomp.split("\t")[1] }.reject { |x| x == "Ticker" }

FileUtils.mkdir_p "#{outputdir}" unless File.exists? "#{outputdir}"

open("#{outputdir}/#{p123id}.json","w") { |f|
  f.puts(JSON.pretty_generate(array))
  puts "File #{outputdir}/#{p123id}.json generated"
}


