#!/usr/bin/env ruby

# used to control Insteon SmartLinc 2414N via commandline
# Author Kenny Austin (http://kenny.aust.in)
# API taken from http://www.leftovercode.info/smartlinc.html

require 'open-uri'
require 'optparse'
require 'yaml'

def usage(why = nil)
  if why
    $stderr.puts why, "\n"
  end
  
  $stderr.puts <<-EOF
Usage: #{__FILE__} <device> <command> <level> [<options>]

Options:
  device      device hardware address
  command     optional, on|faston|off|fastoff|status  default=status
  level       optional, brightness level 0-100
  -c          address of Insteon SmartLinc 2414N controller
  -u          optional, http username
  -p          optional, http password
  -n          create new config file at ~/.2414n.yaml
  
Contoller, username, password, and device aliases can be stored in ~/.2414n.yaml
EOF
	exit(1)
end

# read options from config file
if File.exists?(File.expand_path('~/.2414n.yaml'))
  $config = YAML::load(File.open(File.expand_path('~/.2414n.yaml')))
  if $config and $config['controller']
    if $config['controller']['address']
      $controller = $config['controller']['address']
    end
    if $config['controller']['username']
      $username = $config['controller']['username']
    end
    if $config['controller']['password']
      $password = $config['controller']['password']
    end
  end
end

# get commandline options
OptionParser.new do |o|
  o.on('-n', 'Create config') { |n| $create_config = n }
  o.on('-c S', 'Controller') { |b| $controller = b }
  o.on('-u S', 'Username') { |b| $username = b }
  o.on('-p S', 'Password') { |b| $password = b }
  o.parse!
end
$device = ARGV[0]
$command = ARGV[1]
$level = ARGV[2]


# create new config?
if $create_config
  if ! $config
    $config = {}
  end
  if ! $config['controller']
    $config['controller'] = {}
  end
  if ! $config['controller']['address']
    $config['controller']['address'] = $controller
  end
  if ! $config['controller']['username']
    $config['controller']['username'] = $username
  end
  if ! $config['controller']['password']
    $config['controller']['password'] = $password
  end
  if ! $config['devices']
    $config['devices'] = {}
  end
  if ! $config['devices']['device1']
    $config['devices']['device1'] = 'AB.CD.EF'
  end
  
  File.open(File.expand_path('~/.2414n.yaml'), 'w+') {|f|
    f.write($config.to_yaml) 
  }
  exit;
end

# validate controller
if ! $controller
  usage "Missing controller."
end
if $controller !~ /^https?:\/\//i
  $controller = 'http://' + $controller
end
if $controller !~ /\/$/
  $controller += '/'
end

# substitute cli device with address from config
if $config and $config['devices'] and $config['devices'][$device]
  $device = $config['devices'][$device]
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
  $level = 0
else
  usage "Invalid or unknown command."
end

# convert level to hex
$level = sprintf "%02X" % ($level *2.55).round

# request url
rs = open(
  $controller + '3?0262' + $device + '0F' + String($code) + String($level) + '=I=3',
 :http_basic_authentication => [$username, $password]
)
if rs.status[0] != '200'
  raise rs.status[0] + ' ' + rs.status[1]
end

# check status
if $command == 'status'
  sleep(0.5)
  rs = open($controller + 'buffstatus.xml', :http_basic_authentication => [$username, $password]) { |f|
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
