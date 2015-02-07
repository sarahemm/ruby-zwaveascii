#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'zwaveascii'

zwave = ZWave::ASCII.new ARGV[0], 115200
zwave.debug = true
while(true) do
  events = zwave.fetch_events
  p events if events
  sleep 0.25
end

