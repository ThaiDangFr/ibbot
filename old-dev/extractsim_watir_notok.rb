#!/usr/bin/env ruby


require 'watir'
require 'logger'
require 'json'
require 'fileutils'
require 'iex-ruby-client'


p123id=ARGV[0]

if p123id.nil?
  raise "Syntax : #{__FILE__} <portfolio id>"
end


loginurl = "https://www.portfolio123.com/login.jsp?url=%2F"
pfurl = "https://www.portfolio123.com/holdings.jsp?portid=#{p123id}"
username = ENV['P123USR']
password = ENV['P123PWD']
outputdir = "output"


prefs = {
    'download' => {
        'default_directory' => outputdir,
        'prompt_for_download' => false,
        'directory_upgrade' => true, 
        'extensions_to_open' => '',
    },
    'profile' => {
        'default_content_settings' => {'multiple-automatic-downloads' => 1}, #for chrome version olde ~42
        'default_content_setting_values' => {'automatic_downloads' => 1}, #for chrome newer 46
        'password_manager_enabled' => false,
        'gaia_info_picture_url' => true,
    }
}

#caps = Selenium::WebDriver::Remote::Capabilities.chrome
#caps['chromeOptions'] = {'prefs' => prefs}
#browser = Watir::Browser.new :chrome, :desired_capabilities => caps

#browser = Watir::Browser.new(:chrome, {:chromeOptions => {:args => ['--headless', '--window-size=1200x600']}})
options = ['--headless', '--window-size=1200x600']
#options = ['--window-size=1200x600']
browser = Watir::Browser.new(:chrome, {:chromeOptions => {:args => options, :prefs => prefs }})



browser.goto(loginurl)
browser.input(name: 'LoginUsername').send_keys(username)
browser.input(name: 'LoginPassword').send_keys(password)
browser.input(name: 'Login').click

browser.goto(pfurl)
browser.link(title: "Download").click

sleep 10


exit 0


array = page.content.split("\n").map { |x| x.chomp.split("\t")[1] }.reject { |x| x == "Ticker" }

target = Array.new
array.each do |ticker|
  quote = IEX::Resources::Quote.get(ticker)

  hash = Hash.new
  hash["ticker"] = ticker
  hash["price"] = quote.latest_price
  target.push hash
end


FileUtils.mkdir_p "#{outputdir}" unless File.exists? "#{outputdir}"

open("#{outputdir}/#{p123id}.json","w") { |f|
  f.puts(JSON.pretty_generate(target))
  puts "File #{outputdir}/#{p123id}.json generated"
}


