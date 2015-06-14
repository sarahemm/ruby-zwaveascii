#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'zwaveascii'

zwave = ZWave::ASCII.new ARGV[0], 115200
zwave.debug = true
unit_id = ARGV[1].to_i
puts "\n-----\n\n"

puts "CHECKING BATTERY LEVEL FOR UNIT #{unit_id}"
lock = zwave.door_lock(unit_id)
p lock.battery_level

puts "UNLOCKING UNIT #{unit_id}"
p lock.unlock

puts "LOCKING UNIT #{unit_id}"
p lock.lock

