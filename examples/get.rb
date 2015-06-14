#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'zwaveascii'

zwave = ZWave::ASCII.new ARGV[0], 115200
zwave.debug = true
unit_id = ARGV[1].to_i
puts "\n-----\n\n"

puts "GETTING ON/OFF STATUS OF UNIT #{unit_id}"
switch = zwave.switch(unit_id)
p switch.on?

puts "GETTING LEVEL OF UNIT #{unit_id}"
dimmer = zwave.dimmer(unit_id)
p dimmer.level

