#!/usr/bin/env ruby

require 'mechanize'
require 'logger'
require 'json'
require 'fileutils'
require 'iex-ruby-client'

pfname=ARGV[0]

if pfname.nil?
  raise "Syntax : #{__FILE__} <portfolio name>"
end


loginurl = "https://www.portfolio123.com/login.jsp?url=%2F"
pfurl = "https://www.portfolio123.com/app/trade/accounts"
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

### create portfolio hash ###
liquidation = 0
stocks = Array.new  # [ { "ticker":"AGTC", "shares":"486", "avgcost":"2.99" } ]
portfolio = Hash.new
portfolio["stocks"] = stocks

### parse Liquidation field ###
doc = page.parser
pliq = doc.css('div#trade-cont2 tbody tr').select { |x| x.css('td')[0].text == pfname }.first
liquidation = pliq.css('td')[8].text.gsub(/[^\d^\.]/,'').to_f
portfolio["liquidation"] = liquidation

### parse Current Stock Positions field ###
psto = doc.css('div#pos-tbl-cont table')[1].css('tbody tr').select { |x| x.css('td')[0].text == pfname }
psto.each do |p|
  ticker = p.css('td')[1].css('span')[0].text
  shares = p.css('td')[3].text.to_i
  avgcost = p.css('td')[7].text.gsub(/[^\d^\.]/,'').to_f
  
  quote = IEX::Resources::Quote.get(ticker)

  hash = Hash.new
  hash["ticker"] = ticker
  hash["shares"] = shares
  hash["avgcost"] = avgcost
  hash["price"] = quote.latest_price
  stocks.push hash
end


### create output ###
FileUtils.mkdir_p "#{outputdir}" unless File.exists? "#{outputdir}"
open("#{outputdir}/#{pfname}.json","w") { |f|
  f.puts(JSON.pretty_generate(portfolio))
  puts "File #{outputdir}/#{pfname}.json generated"
}

