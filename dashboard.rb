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
  def initialize(dev=false)
    if not dev
      @browser = Watir::Browser.new(:chrome, {:chromeOptions => {:args => ['--headless', '--window-size=1200x600', '--no-sandbox','--disable-gpu', '--disable-infobars']}})
    else
      @browser = Watir::Browser.new :chrome
    end
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



class WatirAccount
  attr_accessor :browser
  
  # retrieve an array of modelIds
  def rebalanceAll(commit=false)
    strategies = Array.new

    @browser.goto("https://www.portfolio123.com/app/account")
    Watir::Wait.until { @browser.text.include? "Accounts" }

    porfolios = Array.new
    @browser.divs(class: "resp-table-row").each do |d|
      porfolios << d.a.href
    end

    porfolios.each do |p|
      $logger.debug "Go to #{p}"
      @browser.goto(p)

      Watir::Wait.until { @browser.text.include? "Summary" }
      title = @browser.title
      $logger.debug ".. #{title}"
      
      @browser.divs(class: "resp-table-row").each do |s|
        strategies << s.a.href
      end

      reconciliate = @browser.a(text: "journal")
      if reconciliate.exists?
        $logger.debug ".. Reconciling account via journal"
        reconciliate.click
        Watir::Wait.until { @browser.text.include? "Journal Entry" }

        recbut = @browser.button(text: "Apply")
        if recbut.exists?
          recbut.click
        end

        submitbut = @browser.button(text: "Submit")
        if submitbut.exists?
          submitbut.click
        end
      end
    end


    $logger.debug "Rebalancing strategies"
    strategies.each do |s|
      $logger.debug ".. Go to #{s}"
      @browser.goto(s)
      
      Watir::Wait.until { @browser.text.include? "Summary" }
      title = @browser.title
      $logger.debug ".... #{title}"

      @browser.a(class: "dropdown-toggle").click
      @browser.a(text: /Rebalance/).click
      Watir::Wait.until { @browser.text.include? "Rebalance" }
      
      orderlist = @browser.div(text: /Set all to/).span(class: "caret", index: 1)
      if orderlist.exists?
        $logger.debug "....Clicking 'Set all to -> relative 0.01 peg'"
        orderlist.click
        @browser.link(text: /Relative 0.01 peg/).click
      end

      reviewbtn = @browser.button(text: /Review and Send/)
      if reviewbtn.exists?
        $logger.debug "....Clicking Review and Send"
        reviewbtn.click
      end

      if commit
        confirmbtn = @browser.button(text: "Confirm")
        if confirmbtn.present? and not confirmbtn.disabled?
          $logger.debug "....Clicking Confirm"
          confirmbtn.click
        end    
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

    options[:rebalance] = false
    opts.on('--rebalance', 'Rebalance model ids' ) do |t|
      options[:rebalance] = t
    end
    
    options[:dev] = false
    opts.on('--dev', 'Running in dev mode' ) do |t|
      options[:dev] = t
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
  commit=options[:commit]
  testonly=options[:testonly]
  rebalance=options[:rebalance]
  dev=options[:dev]

  mandatory = [:username, :password]                                        
  missing = mandatory.select{ |param| options[param].nil? }            
  if not missing.empty?                                                 
        puts "Missing options: #{missing.join(', ')}"                   
        puts optparse.help                                              
        exit 2                                                          
  end  


  $logger.debug "--BEGIN--"

  watirconnect = WatirConnect.new(dev)
  watirconnect.login(username, password)
  browser = watirconnect.browser

  if rebalance
    watiraccount = WatirAccount.new
    watiraccount.browser = browser
    watiraccount.rebalanceAll(commit)
  end
  

rescue => err
  $logger.fatal("Caught exception; exiting")
  $logger.fatal(err)
  exit 1

ensure
  $logger.debug "--END--"
end

