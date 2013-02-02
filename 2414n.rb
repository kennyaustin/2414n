#!/usr/bin/env ruby

# used to control Insteon SmartLinc 2414N via commandline
# Author Kenny Austin (http://kenny.aust.in)
# API taken from http://www.leftovercode.info/smartlinc.html

require 'open-uri'
require 'optparse'

def usage(why = nil)
  if why
    $stderr.puts why, "\n"
  end
  
  $stderr.puts <<-EOF
Usage: #{__FILE__} controller device command level [options]

Options:
  controller  controller address of Insteon SmartLinc 2414N
  device      device hardware address
  command     optional, on|faston|off|fastoff|status  default=status
  level       optional, brightness level 0-100
  -u          optional, http username
  -p          optional, http password
EOF
	exit(1)
end

# get commandline options
$controller = ARGV[0]
$device = ARGV[1]
$command = ARGV[2]
$level = ARGV[3]
OptionParser.new do |o|
  o.on('-u S', 'Username') { |b| $username = b }
  o.on('-p S', 'Password') { |b| $password = b }
  o.parse!
end

# validate site
if ! $controller
  usage "Missing controller."
end
if $controller !~ /^https?:\/\//i
  $controller = 'http://' + $controller
end
if $controller !~ /\/$/
  $controller += '/'
end

# validate device id
if ! $device or $device.upcase !~ /^([0-9|A-F]{2})\.?([0-9|A-F]{2})\.?([0-9|A-F]{2})$/
  usage "Invalid device id."
end
$device = $1 + $2 + $3

# validate level
if $level
  if $level !~ /^(100|\d{1,2})%?$/
    usage "Invalid level value."
  end
  $level = Integer($1)
end

# validate comamnds and get $code
if ! $command 
  $command = 'status'
end
case $command.downcase
when 'on'
  if $level and $level == 0
    $code = 13 # off
  else
    $code = 11
    if ! $level then
      $level = 100
    end    
  end
when 'faston'
  if $level and $level == 0
    $code = 14 # fastoff
  else
    $code = 12
    if ! $level then
      $level = 100
    end    
  end  
when 'off'
  if $level and $level > 0
    $code = 11 # on
  else
    $code = 13
    $level = 0
  end
when 'fastoff'
  if $level and $level > 0
    $code = 14 #faston
  else
    $code = 14
    $level = 0
  end
when 'status'
  $code = 19
  $level = 100
else
  usage "Invalid or unknown command."
end

# convert level to hex
$level = sprintf "%-02X" % ($level *2.55).round

# request url
rs = open($controller + '3?0262' + $device + '0F' + String($code) + String($level) + '=I=3')
if rs.status[0] != '200'
  raise rs.status[0] + ' ' + rs.status[1]
end

# check status
if $command == 'status'
  sleep(0.5)
  rs = open($controller + 'buffstatus.xml'){ |f|
    str = f.read()
    if str !~ /^<response><BS>([0-9|A-F]{16})(06|15)0250([0-9|A-F]{6})([0-9|A-F]{6})2([0-9|A-F])([0-9|A-F]{2})([0-9|A-F]{2})/
      raise "Error parsing response."
    elsif $1 != '0262' + $device + '0F' + String($code) + String($level)
      raise "Response from wrong device.  Try again."
    end
        
    # new level, but make sure it doesn't round to 0
    rs = ($7.to_i(16) /2.55);
    if rs > 0 and rs < 1 then
      rs = 1
    else
      rs = rs.round
    end
    print rs
  }
end
