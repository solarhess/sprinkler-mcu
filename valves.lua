--------------------------------------
-- shiftregisterout.lua
-- Author: Jonathan Hess
--
-- Logic for sprinkler valves
-- 

module("valves", package.seeall)


local valve_wait_time_ms = 1000
local startup_timer_id = 1
local timer_started = false
local active_sprinkler = nil
require "shiftregisterout"

function valves.turn_all_off()
  active_sprinkler = nil
  write(0xFFFF)
  if timer_started then
    tmr.unregister(startup_timer_id)
  end
  shiftregisterout.output_enable(false)
end

function valves.enable(valve_index, run_time_ms)
  turn_all_off()
  active_sprinkler = valve_index
  timer_started = tmr.alarm(startup_timer_id, valve_wait_time_ms, tmr.ALARM_SINGLE,
    function()
      print("Opening Sprinkler",valve_index)
      write(bit.bxor(0xFFFF, bit.lshift(1, valve_index)))
      -- now turn off the valve after 
      timer_started = tmr.alarm(startup_timer_id, run_time_ms, tmr.ALARM_SINGLE, turn_all_off)
    end)
  if timer_started then 
    print("timer started")
  else
    print("nope!")
  end
end
