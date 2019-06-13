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

  def rebalance(modelid)
    raise "Cannot rebalance because no browser defined" if @browser.nil?

    reburl = "https://www.portfolio123.com/portf_rebalance.jsp?portid=#{modelid}"
    @browser.goto(reburl)

    rebalbtn = @browser.button(text: /Reconstitute & Rebalance/)
    if rebalbtn.exists?
      $logger.debug "Clicking 'Reconstitute & Rebalance'"
      rebalbtn.click
    end
      
    recalert = @browser.div(id: "recs-alert")
    txtbefore = recalert.text
    $logger.debug "Status : #{txtbefore}"

    btngetrec = @browser.button(id: "btn-get-recs")
    if not btngetrec.disabled? and btngetrec.exists?
      $logger.debug "Clicking 'Get Recommendations'"
      btngetrec.click
    end

    Watir::Wait.until { recalert.text != txtbefore }
    txtafter = recalert.text
    $logger.debug "New status : #{txtafter}"
    
    btncommit = @browser.button(id: "recs-commit")

    if btncommit.present? and not btncommit.disabled?
      btncommit.click
      Watir::Wait.until { recalert.text != txtafter }
      $logger.debug "Rebalance : committed"
    else
      $logger.debug "Rebalance : nothing to commit"
    end
    
  end

  def runtest(modelid)
    raise "Cannot runtest because no browser defined" if @browser.nil?

    reburl = "https://www.portfolio123.com/portf_rebalance.jsp?portid=#{modelid}"
    @browser.goto(reburl)

    recsalert = @browser.div(id: "recs-alert").exists?
    btngetrecs = @browser.button(id: "btn-get-recs").exists?
    recscommit = @browser.button(id: "recs-commit").exists?
    
    if recsalert and btngetrecs and recscommit
      $logger.debug "#{modelid} : rebalance page is conform"
    else
      raise "#{modelid} : rebalance page is not conform !"
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

  
  
  


rescue => err
  $logger.fatal("Caught exception; exiting")
  $logger.fatal(err)
  exit 1

ensure
  $logger.debug "--END--"
end

