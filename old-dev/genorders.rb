#!/usr/bin/env ruby

require 'logger'
require 'json'
require 'fileutils'

CASHPCT = 0.02 # 2% stay in cash
SLIPPAGE = 0.0025 # 0.25%
SELLPRICE = 1-SLIPPAGE
BUYPRICE = 1 + SLIPPAGE
outputdir = "output"


if ARGV.length < 3
  raise "Syntax : #{__FILE__} <portfolio name> <sim id> <percent>"
end

pfname = ARGV[0]
simid = ARGV[1]
pctid = ARGV[2]

pf = "output/#{pfname}.json"


target = "output/#{simid}.json"


orders = Array.new

jpf = JSON.parse(File.read(pf))
jtarget = JSON.parse(File.read(target))
target_ticker_price_hash = jtarget.map { |x| [x["ticker"], x["price"]] }.to_h

#p target_ticker_price_hash

liquidation = (jpf["liquidation"].to_f)*pctid.to_f/100
availablecash = liquidation*(1-CASHPCT)
nb = target_ticker_price_hash.length

maxmktvalue = availablecash / nb

jpf["stocks"].each do |h|
  ticker = h["ticker"]
  shares = h["shares"].to_i
  avgcost = h["avgcost"].to_f
  price = h["price"].to_f

  # SELL if not in target
  if not target_ticker_price_hash.key? ticker
    orders.push "#{ticker} SELL #{shares} LIMIT:#{(price*SELLPRICE).round(2)}"
    next
  end

  mktvalue = shares*price
  delta = maxmktvalue - mktvalue

  if delta < 0 # SELL if there are too many
    shares_to_sell = (-delta / price).round
    orders.push "#{ticker} SELL #{shares_to_sell} LIMIT:#{(price*SELLPRICE).round(2)}" unless shares_to_sell == 0

  elsif delta > 0 # BUY if there are not enough
    shares_to_buy = (delta / price).round
    orders.push "#{ticker} BUY #{shares_to_buy} LIMIT:#{(price*BUYPRICE).round(2)}" unless shares_to_buy == 0
  end

end

pfstocks = jpf["stocks"].map { |x| x["ticker"] }

# BUY if it is in target and not in pf
target_ticker_price_hash.each do |t,p|
  if not pfstocks.include? t
    ticker = t
    price = p
    shares_to_buy = (maxmktvalue / price).round
    orders.push "#{ticker} BUY #{shares_to_buy} LIMIT:#{(price*BUYPRICE).round(2)}" unless shares_to_buy == 0
  end
end




FileUtils.mkdir_p "#{outputdir}" unless File.exists? "#{outputdir}"
filename = "#{pfname}-#{simid}-orders.txt"
open("#{outputdir}/#{filename}","w") { |f|
  f.puts(orders)
  puts "File #{outputdir}/#{filename} generated"
}

