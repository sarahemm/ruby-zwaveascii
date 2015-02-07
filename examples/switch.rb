#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'zwaveascii'

zwave = ZWave::ASCII.new ARGV[0]
zwave.debug = true
unit_id = ARGV[1].to_i
puts "\n-----\n\n"

puts "SWITCHING UNIT #{unit_id} OFF"
switch = zwave.switch(unit_id)
switch.on = false

sleep 2

puts "SWITCHING UNIT #{unit_id} ON"
switch.on = true

