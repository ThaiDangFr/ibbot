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
require 'byebug'
require 'test/unit'
require 'open3'



$logger = Logger.new(STDOUT)
$logger.level = Logger::DEBUG
$logger.formatter = proc do |severity, datetime, progname, msg|
  date_format = datetime.strftime("%d-%m-%Y %H:%M:%S.%6N")
  "#{severity[0]} [#{date_format}] : #{msg}\n"
end

class TestIbbot < Test::Unit::TestCase

  ### PARSE OPTIONS ###

  begin
    options = {}
    optparse = OptionParser.new do |opts|
      opts.banner = "Usage: #{__FILE__} [options]"

      opts.on('--username USERNAME', 'Portfolio123 username' ) do |username|
        options[:username] = username
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
    
    PFNAME=options[:pf_name]
    USERNAME=options[:username]
    PASSWORD=options[:password]
    SIM=options[:sim]

    mandatory = [:username, :password, :sim, :pf_name]                                        
    missing = mandatory.select{ |param| options[param].nil? }            
    if not missing.empty?                                                 
      puts "Missing options: #{missing.join(', ')}"                   
      puts optparse.help                                              
      exit 2                                                          
    end  

  rescue => err
    $logger.fatal("Caught exception; exiting")
    $logger.fatal(err)
    exit 1
  end

  ### BEGIN OF TEST ###

  def shell(command)
    stdout, stderr, status = Open3.capture3(command)
    if not status.success?
      $logger.fatal stdout
      raise stderr
    end

    stdout
  end


  def clean
    if File.exists? "#{PFNAME}.png"
      File.delete "#{PFNAME}.png"
    end
  end


  def extractLiquidation(txt)
    txt.match(/.*liquidation = (.*)/)[1].to_f
  end

  def extractOrders(txt)
    txt.match(/.*Orders:[\n](.*)[\n].*Trading.*/m)[1]
  end

  def calculate_orders(orders)
    total = 0
    orders.split("\n").each do |o|
      if o.include? "SELL"
        md = o.match(/.*SELL (.*) LIMIT:(.*)/)
        qty = md[1].to_f
        limit = md[2].to_f
        total -= qty*limit
      elsif o.include? "BUY"
        md = o.match(/.*BUY (.*) LIMIT:(.*)/)
        qty = md[1].to_f
        limit = md[2].to_f
        total += qty*limit
      end
    end

    total
  end
  

  def test_import_empty_sim
    $logger.debug "test_import_empty_sim"
    txt = shell("./ibbot.rb -v --username #{USERNAME} --password #{PASSWORD} --import_pf #{PFNAME}")
    liquidation = extractLiquidation(txt)
    orders = extractOrders(txt)

    $logger.debug "Check that liquidation is a number and positive"
    assert liquidation > 0

    $logger.debug "Check that orders contains only SELL"
    assert orders.scan(/(.*SELL.*)/).length > 0
    assert orders.scan(/(.*BUY.*)/).length == 0
    
    total = calculate_orders(orders)
    ratiopct = ((1-(-total/liquidation))*100).round(2)
    
    $logger.debug "Check that total of sell not too far from liquidation : 0 < #{ratiopct}% < 5%"
    assert ratiopct < 5
    assert ratiopct > 0

    clean
  end

  def test_import_real_sim
    $logger.debug "test_import_real_sim"
    
    a = Array.new
    SIM.each do |s|
      a.push "--import_sim #{s}"
    end
    importsims = a.join(" ")

    txt = shell("./ibbot.rb -v --username #{USERNAME} --password #{PASSWORD} --import_pf #{PFNAME} #{importsims}")
    liquidation = extractLiquidation(txt)
    orders = extractOrders(txt)

    $logger.debug "Check that liquidation is a number and positive"
    assert liquidation > 0

    $logger.debug "Check that orders contains SELL and BUY"
    assert orders.scan(/(.*SELL.*)/).length > 0
    assert orders.scan(/(.*BUY.*)/).length > 0

    total = calculate_orders(orders)

    $logger.debug "Check that total of orders : -liquidation < #{total.round(2)} < +liquidation"
    assert total > -liquidation
    assert total < liquidation

    clean
  end



end

