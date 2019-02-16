#!/usr/bin/env ruby

require 'mechanize'
require 'logger'
require 'json'
require 'fileutils'
require 'iex-ruby-client'

pfname = ARGV[0]
orderfile = ARGV[1]

if pfname.nil? or orderfile.nil?
  raise "Syntax : #{__FILE__} <portfolio name> <order file>"
end


loginurl = "https://www.portfolio123.com/login.jsp?url=%2F"
tradeurl = "https://www.portfolio123.com/app/trade/orderBatch"
username = ENV['P123USR']
password = ENV['P123PWD']
outputdir = "output"


ordertxt = File.read(orderfile)


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

page = agent.get(tradeurl)

# pp page =>
#  #<Mechanize::Form
#   {name "add-order-form"}
#   {method "GET"}
#   {action "https://www.portfolio123.com/app/trade/orderBatch"}
#   {fields
#    [text:0x831238 type: text name: batch_source_name value: Manual]
#    [hidden:0x830e50 type: hidden name: order_cnt value: 0]
#    [hidden:0x830a54 type: hidden name: valid_order_cnt value: 0]
#    [hidden:0x82feec type: hidden name: error_order_cnt value: 0]
#    [textarea:0x82b568 type:  name: batch_txt value: ]
#    [selectlist:0x7dd520 type:  name: batch_account_uid value: 122]
#    [selectlist:0x743718 type:  name: batch_order_type_uid value: 1]}
#   {radiobuttons}
#   {checkboxes}
#   {file_uploads}
#   {buttons}>}>

# find the batch_account_uid associated with pfname
doc = page.parser
batch_account_uid = doc.css("select#batch_account_uid").css("option").select { |x| x.text.include? pfname }.first.attr("value")


form = page.forms_with("add-order-form").first
form["batch_source_name"] = "ibbot #{Time.now}"
form["batch_order_type_uid"] = "2"
form["batch_txt"] = ordertxt
form["batch_account_uid"] = batch_account_uid
form.method = "POST"

page2 = agent.submit(form)

form2 = page2.forms_with("add-order-form").first
form2["valid_order_cnt"] = "0"
form2["verifyOrders"] = "1"
form2.method = "POST"

page3 = agent.submit(form2)


form3 = page3.forms_with("add-order-form").first
form3.method = "POST"

pp form3

#page4 = agent.submit(form3)













