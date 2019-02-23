#!/usr/bin/env ruby

require 'mechanize'
require 'logger'
require 'json'
require 'fileutils'
require 'iex-ruby-client'
require 'fileutils'
require 'watir'
require 'optparse'
require 'pp'

SLIPPAGE = 0.0025 # 0.25%
$logger = Logger.new(STDOUT)
$logger.level = Logger::ERROR

class Stock
  #code=ticker, shares=nb of shares, avgcost=average cost, pct=percent you want to allocate
  #liquidation=the total amount of money you have for investing 
  attr_accessor :code, :shares, :avgcost, :pct, :liquidation , :last

  def initialize(code)
    @code = code
    @last = IEX::Resources::Quote.get(code).latest_price
    @liquidation = 0.0
    @shares = 0
    @avgcost = 0.0
    @pct = 0.0
  end

  def mktvalue
    @last*@shares
  end

  def targetmktvalue
    @liquidation.to_f*@pct.to_f/100
  end

  def delta
    targetmktvalue-mktvalue
  end

  def sell_price
    (@last*(1-SLIPPAGE)).round(2)
  end

  def buy_price
    (@last*(1+SLIPPAGE)).round(2)
  end

  def sell_quantity
    if targetmktvalue==0
      @shares
    else
      if delta < 0
        (-delta/sell_price).round
      else
        0
      end
    end
  end

  def buy_quantity
    if delta > 0
      (delta/buy_price).round
    else
      0
    end
  end

  def order
    if buy_quantity > 0
      "#{@code} BUY #{buy_quantity} LIMIT:#{buy_price}"
    elsif sell_quantity > 0
      "#{@code} SELL #{sell_quantity} LIMIT:#{sell_price}"
    end
  end

  def profit_loss
    (@last-@avgcost)*shares
  end

  def print_debug
    $logger.debug("#{@code} | #{@shares} | #{@avgcost} | #{@pct} % | #{order} | #{profit_loss}")
  end
end


class StockArray < Array
  def merge(array)
    array.each do |newstock|
      existing = self.find_all { |s| s.code == newstock.code }
      
      existing.each do |existingstock|
        existingstock.shares +=  newstock.shares
        existingstock.pct +=  newstock.pct
      end

      if existing.empty?
        self.push newstock
      end

    end
  end

  def print_debug_header
    $logger.debug("code | shares | avgcost | pct % | order | profit_loss")
  end

  def print_debug
    self.each do |s|
      s.print_debug
    end
  end

  def print_stocklist
    $logger.debug self.map { |x| x.code}.join(" ")
  end
end



class Portfolio < StockArray
  attr_accessor :username, :password, :pfname, :liquidation

  def initialize(username, password, pfname)
    @username = username
    @password = password
    @pfname = pfname

    @agent = Mechanize.new
    @agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
    @agent.user_agent_alias = 'Linux Firefox'
  end

  def login
    loginurl = "https://www.portfolio123.com/login.jsp?url=%2F"
    page = @agent.get(loginurl)
    form = page.forms.first


    form["LoginUsername"] = @username
    form["LoginPassword"] = @password
    form["url"] = "/"
    @agent.submit(form, form.buttons.first)

    $logger.debug("Authentication OK")
  end

  def import
    pfurl = "https://www.portfolio123.com/app/trade/accounts"
    page = @agent.get(pfurl)

    ### parse Liquidation field ###
    doc = page.parser
    pliq = doc.css('div#trade-cont2 tbody tr').select { |x| x.css('td')[0].text == @pfname }.first
    @liquidation = pliq.css('td')[8].text.gsub(/[^\d^\.]/,'').to_f
    
    $logger.debug "liquidation = #{@liquidation}"

    ### parse Current Stock Positions field ###
    psto = doc.css('div#pos-tbl-cont table')[1].css('tbody tr').select { |x| x.css('td')[0].text == @pfname }
    psto.each do |p|
      ticker = p.css('td')[1].css('span')[0].text
      shares = p.css('td')[3].text.to_i
      avgcost = p.css('td')[7].text.gsub(/[^\d^\.]/,'').to_f

      stock = Stock.new(ticker)
      stock.shares = shares
      stock.avgcost = avgcost
      stock.liquidation = @liquidation

      self.push stock
    end
    
    $logger.debug "#{self.length} stocks imported"
  end



end

class Simulation < Portfolio
  attr_accessor :username, :password, :simid

  def initialize(username, password, simid)
    super
    @simid = simid
  end

  def import
    pfurl = "https://www.portfolio123.com/p123/DownloadPortHoldings?portid=#{@simid}"
    page = @agent.get(pfurl)
    array = page.content.split("\n").map { |x| x.chomp.split("\t")[1] }.reject { |x| x == "Ticker" }
    array.each do |ticker|
      stock = Stock.new(ticker)
      self.push stock
    end

    $logger.debug "#{self.length} stocks imported"
  end


end




begin

  options = {}
  optparse = OptionParser.new do |opts|
    opts.banner = "Usage: #{__FILE__} [options]"

    options[:logfile] = nil
    opts.on('-l', '--logfile FILE', 'Write log to FILE' ) do |file|
      options[:logfile] = file
      $logger = Logger.new(file)
    end

    options[:verbose] = false
    opts.on('-v', '--verbose', 'Output more information') do
      options[:verbose] = true
      $logger.level = Logger::DEBUG
    end

    opts.on('--login LOGIN', 'Portfolio123 login' ) do |login|
      options[:login] = login
    end
    
    opts.on('--password PASSWORD', 'Portfolio123 password' ) do |password|
      options[:password] = password
    end

    opts.on('--import_pf PF_NAME', 'Portfolio name' ) do |pf_name|
      options[:pf_name] = pf_name
    end

    options[:sim] = Array.new
    opts.on('--import_sim SIMID:PCT', 'Simulation ID:Percent allocated' ) do |sim|
      options[:sim] << sim
    end

    opts.on( '-h', '--help', 'Display this screen' ) do
      puts opts
      exit
    end
  end

  optparse.parse!
  puts "Being verbose" if options[:verbose]
  puts "Logging to file #{options[:logfile]}" if options[:logfile]
    
  pf_name=options[:pf_name]
  login=options[:login]
  password=options[:password]
  sim=options[:sim]

  mandatory = [:login, :password]                                        
  missing = mandatory.select{ |param| options[param].nil? }            
  if not missing.empty?                                                 
        puts "Missing options: #{missing.join(', ')}"                   
        puts optparse.help                                              
        exit 2                                                          
  end  







  totalportfolio = StockArray.new
  liquidation = 0

  if not pf_name.nil?
    $logger.debug("Importing #{pf_name}")
    portfolio = Portfolio.new(login,password,pf_name)
    portfolio.login
    portfolio.import
    liquidation = portfolio.liquidation

    portfolio.print_stocklist   
    totalportfolio.merge(portfolio)
  end
  
  sim.each do |x|
    simid = x.split(':')[0]
    pct = x.split(':')[1]

    $logger.debug "Importing Sim #{simid} for #{pct}%"
    simulation = Simulation.new(login,password,simid)
    simulation.login
    simulation.import
    simulation.print_stocklist

    len = simulation.length
    pct_each = pct.to_f/len
    simulation.each do |s|
      s.pct = pct_each
    end

    #simulation.print_debug
    totalportfolio.merge(simulation)
  end

  totalportfolio.each do |s|
    s.liquidation = liquidation
  end

  $logger.debug "Total portfolio length = #{totalportfolio.length}"
  totalportfolio.print_debug_header
  totalportfolio.print_debug



rescue => err
  $logger.fatal("Caught exception; exiting")
  $logger.fatal(err)
end

