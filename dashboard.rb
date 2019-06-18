#!/usr/bin/env ruby

#require 'mechanize'
require 'logger'
require 'json'
require 'fileutils'
require 'iex-ruby-client'
require 'fileutils'
require 'watir'
require 'optparse'
require 'pp'
require 'byebug'
require 'webdrivers'


Webdrivers.cache_time = 86400 # https://github.com/titusfortner/webdrivers#caching-drivers

$logger = Logger.new(STDOUT)
$logger.level = Logger::ERROR



# http://watir.com/guides/chrome/
class WatirConnect
   attr_accessor :browser

  # on the VM avoid to have a chrome opened
  # otherwise you could have :
  #   Caught exception; exiting
  #   Net::ReadTimeout
  # if there is not enough memory 
  def initialize
    @browser = Watir::Browser.new(:chrome, {:chromeOptions => {:args => ['--headless', '--window-size=1200x600', '--no-sandbox','--disable-gpu', '--disable-infobars']}})
    #@browser = Watir::Browser.new :chrome
  end

  def login(username, password)
    loginurl = "https://www.portfolio123.com/app/auth"
    @browser.goto(loginurl)
    title = @browser.title

    @browser.input(name: 'user').send_keys(username)
    @browser.input(name: 'passwd').send_keys(password)
    @browser.button(value: 'Submit').click

    @browser.wait_until { @browser.title != title }

    $logger.debug("Authentication OK")
  end
end



class WatirFund
  attr_accessor :browser

  def rebalance(modelid, commit=false)
    raise "Cannot rebalance because no browser defined" if @browser.nil?

    reburl = "https://www.portfolio123.com/app/investment/details?id=#{modelid}&t=rebalance"
    @browser.goto(reburl)

    orderlist = @browser.div(text: /Set all to/).span(class: "caret", index: 1)
    if orderlist.exists?
      $logger.debug "Clicking 'Set all to -> relative 0.01 peg'"
      orderlist.click
      @browser.link(text: /Relative 0.01 peg/).click
    end

    reviewbtn = @browser.button(text: /Review and Send/)
    if reviewbtn.exists?
      $logger.debug "Clicking Review and Send"
      reviewbtn.click
    end

    if commit
      confirmbtn = @browser.button(text: "Confirm")
      if confirmbtn.present? and not confirmbtn.disabled?
        $logger.debug "Clicking Confirm"
        confirmbtn.click
      end    
    end

  end
end






begin

  options = {}
  optparse = OptionParser.new do |opts|
    opts.banner = "Usage: #{__FILE__} [options]"

    options[:logfile] = nil
    opts.on('-l', '--logfile FILE', 'Write log to FILE' ) do |file|
      options[:logfile] = file
      $logger = Logger.new(file, 10, 4096000)
    end

    options[:verbose] = false
    opts.on('-v', '--verbose', 'Output more information') do
      options[:verbose] = true
      $logger.level = Logger::DEBUG
    end

    opts.on('--username USERNAME', 'Portfolio123 username' ) do |username|
      options[:username] = username
    end
    
    opts.on('--password PASSWORD', 'Portfolio123 password' ) do |password|
      options[:password] = password
    end


    options[:modelids] = Array.new
    opts.on('--modelid MODELID', 'Model ids' ) do |sim|
      options[:modelids] << sim
    end

    options[:rebalance] = false
    opts.on('--rebalance', 'Rebalance model ids' ) do |t|
      options[:rebalance] = t
    end
    

    options[:commit] = false
    opts.on('--commit', 'Send order to trade' ) do |t|
      options[:commit] = t
    end

    options[:testonly] = false
    opts.on('--testonly', 'Doing only some tests' ) do |t|
      options[:testonly] = t
    end

    opts.on( '-h', '--help', 'Display this screen' ) do
      puts opts
      exit
    end
  end

  optparse.parse!
  puts "Being verbose" if options[:verbose]
  puts "Testing mode" if  options[:testonly]
  puts "Logging to file #{options[:logfile]}" if options[:logfile]
  puts "!! TRADE will be commited !!" if options[:commit]
    
  # change $logger format
  $logger.formatter = proc do |severity, datetime, progname, msg|
    date_format = datetime.strftime("%d-%m-%Y %H:%M:%S.%6N")
      "#{severity[0]} [#{date_format}] : #{msg}\n"
  end


  username=options[:username]
  password=options[:password]
  modelids=options[:modelids]
  commit=options[:commit]
  testonly=options[:testonly]
  rebalance=options[:rebalance]

  mandatory = [:username, :password]                                        
  missing = mandatory.select{ |param| options[param].nil? }            
  if not missing.empty?                                                 
        puts "Missing options: #{missing.join(', ')}"                   
        puts optparse.help                                              
        exit 2                                                          
  end  


  $logger.debug "--BEGIN--"

  watirconnect = WatirConnect.new
  watirconnect.login(username, password)
  browser = watirconnect.browser

  watirfund = WatirFund.new
  watirfund.browser = browser

  if rebalance
    modelids.each do |modelid|
      $logger.debug "Rebalancing #{modelid}"
      watirfund.rebalance(modelid, commit)
    end
  end
  


  


rescue => err
  $logger.fatal("Caught exception; exiting")
  $logger.fatal(err)
  exit 1

ensure
  $logger.debug "--END--"
end

