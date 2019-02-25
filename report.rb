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
require 'tempfile'


$logger = Logger.new(STDOUT)
$logger.level = Logger::ERROR

begin

  options = {}
  optparse = OptionParser.new do |opts|
    opts.banner = "Usage: #{__FILE__} [options]"

    options[:verbose] = false
    opts.on('-v', '--verbose', 'Output more information') do
      options[:verbose] = true
      $logger.level = Logger::DEBUG
    end

    opts.on('--email EMAIL', 'Email you want to send the report to' ) do |email|
      options[:email] = email
    end

    opts.on('--subject SUBJECT', 'Email subject' ) do |subject|
      options[:subject] = subject
    end

    options[:logfile] = "*.log"
    opts.on('--logfile LOGFILE', 'Files to include in the report' ) do |logfile|
      options[:logfile] = logfile
    end

    opts.on( '-h', '--help', 'Display this screen' ) do
      puts opts
      exit
    end
  end

  # change $logger format
  $logger.formatter = proc do |severity, datetime, progname, msg|
    date_format = datetime.strftime("%d-%m-%Y %H:%M:%S.%6N")
    "#{severity[0]} [#{date_format}] : #{msg}\n"
  end

  optparse.parse!
  puts "Being verbose" if options[:verbose]
    
  mandatory = [:email, :subject]                                        
  missing = mandatory.select{ |param| options[param].nil? }            
  if not missing.empty?                                                 
        puts "Missing options: #{missing.join(', ')}"                   
        puts optparse.help                                              
        exit 2                                                          
  end  


  total = Array.new


  logfiles = Dir.glob(options[:logfile])
  logfiles.each do |logfile|
    part = Array.new
    $logger.debug "Parsing #{logfile}"
    File.readlines(logfile).reverse_each do |s|
      part.push(s)
     break if s.include? "--BEGIN--"
    end
    
    total.push("------ ").push(logfile).push(" ------").push("\n")
    total << part.reverse
  end

  Tempfile.create do |f|
    f.write total.join
    f.close
    system("mail -s '#{options[:subject]}' #{options[:email]} < #{f.path}")
  end



rescue => err
  $logger.fatal("Caught exception; exiting")
  $logger.fatal(err)
  exit 1

ensure
end

