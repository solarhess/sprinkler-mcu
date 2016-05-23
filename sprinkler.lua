--------------------------------------
-- shiftcontrol.lua
-- Author: Jonathan Hess
--
-- Allows you to control a 2-chain shift register
--
--
-- Wiring Connections for 74hc595
-- pin     GPIO #IO     595 pin     
-- srclk   14              11
-- rclk     4    2         12
-- !oe      5    1         13
-- ser     13              14
-- 
local latch_pin = 2 -- constant for latch pin
local oe_pin = 1 -- constant for OE pin

-----------------------
-- setup() Initializes the GPIO, resets to 0
-- send  
function setup(pinmask)
  gpio.mode(latch_pin, gpio.OUTPUT)
  gpio.write(latch_pin, gpio.LOW)
  gpio.mode(oe_pin, gpio.OUTPUT, gpio.PULLUP)
  result = spi.setup(1, spi.MASTER, spi.CPOL_HIGH, spi.CPHA_LOW, 16, 0)
  write(pinmask)
  output_disable()
end

function output_enable()
    gpio.write(oe_pin, gpio.LOW)
end

function output_disable()
    gpio.write(oe_pin, gpio.HIGH)
end

function write(pinmask)
    spi.send(1, pinmask) -- daisychained registers... value1 is the end of the chain, value2 is connected to gpio
    gpio.write(latch_pin, gpio.HIGH)
    gpio.write(latch_pin, gpio.LOW)
    output_enable()
end



------------------------------
-- Sprinkler Control Features
-- This logic turns valves on and off.
--

local valve_wait_time_ms = 1000
local startup_timer_id = 1
local timer_started = false
local active_sprinkler = nil

function turn_all_off()
  active_sprinkler = nil
  write(0xFFFF)
  if timer_started then
    tmr.unregister(startup_timer_id)
  end
  output_disable()
end

function enable_sprinkler(valve_index, run_time_ms)
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


srv = nil
function setup_server()
  function handle_request(sck, req)
      _, _, path = string.find(req,"GET%s(/%S*)%sHTTP")
      local response = nil
      print("GET Path", path)
      if path == nil then
        response = {"HTTP/1.0 404 NOT FOUND\r\nServer: NodeMCU on ESP8266\r\nContent-Type: text/html\r\n\r\n"} 
        response[#response + 1] = "<h1>404 Not Found</h1><p><a href='/'>Home</a></p>"
      elseif path == "/" then
        response = {"HTTP/1.0 200 OK\r\nServer: NodeMCU on ESP8266\r\nContent-Type: text/html\r\n\r\n"}
        response[#response + 1] = "<h1>Sprinkler Control</h1>"
        response[#response + 1] = "<p>Use /<index>/<min> to turn on a sprinkler for a period of seconds. eg GET /3/15 turns on valve 3 for 15 minutes</p>"
        if active_sprinkler ~= nil then
          response[#response + 1] = "<h2>Active Sprinkler: ".. active_sprinkler  .."</h2>"
        end
        response[#response + 1] = "<h2>Actions</h2>"
        response[#response + 1] = "<ul>"
        for i=0,15 do
          response[#response + 1] = "<li><a href='/"..i.."/300'>Zone "..i.." 5 min</a></li>"
        end
        response[#response + 1] = "<li><a href='/off'>All Off</a></li></ul>"

      elseif path == "/off" then
        turn_all_off()
        response = {"HTTP/1.0 200 OK\r\nServer: NodeMCU on ESP8266\r\nContent-Type: text/html\r\n\r\n"}
        response[#response + 1] = "<h1>Sprinkler Control</h1>"
        response[#response + 1] = "<p>All Off</p>"
        response[#response + 1] = "<p><a href='/'>Home</a></p>"
      else
        _, _, valve, min = string.find(path, "/(%d+)/(%d+)")
        if(valve ~= nil) then
          enable_sprinkler(tonumber(valve), tonumber(min) * 1000)
          response = {"HTTP/1.0 200 OK\r\nServer: NodeMCU on ESP8266\r\nContent-Type: text/html\r\n\r\n"}
          response[#response + 1] = "<h1>Enabled Valve "
          response[#response + 1] = valve
          response[#response + 1] = " for "
          response[#response + 1] = min
          response[#response + 1] = " seconds"
          response[#response + 1] = "</h1>"
          response[#response + 1] = "<p>Use GET /[valve index]/[seconds] to turn on a sprinkler for a period of seconds. eg GET /3/15 turns on valve 3 for 15 minutes</p>"
          response[#response + 1] = "<p><a href='/'>Home</a></p>"
          response[#response + 1] = "<p><a href='/'>Home</a></p>"
        end
      end

      if response == nil then
        response = {"HTTP/1.0 404 NOT FOUND\r\nServer: NodeMCU on ESP8266\r\nContent-Type: text/html\r\n\r\n"} 
        response[#response + 1] = "<h1>404 Not Found</h1><p><a href='/'>Home</a></p>"
      end


       -- sends and removes the first element from the 'response' table
      local function send()
        if #response > 0
          then sck:send(table.remove(response, 1))
        else
          sck:close()
        end
      end

      -- triggers the send() function again once the first chunk of data was sent
      sck:on("sent", send)
      send()
    end


  srv = net.createServer(net.TCP)
  srv:listen(80, function(conn)
    conn:on("receive", handle_request)
  end)
end

function setup_wifi() 
  wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(T) 
    print("\n\tSTA - GOT IP".."\n\tStation IP: "..T.IP.."\n\tSubnet mask: "..
    T.netmask.."\n\tGateway IP: "..T.gateway)
    mdns.register("sprinkler",{description="Sprinkler Control", service="http", port=80, location="Basement"})
    setup_server()
  end)

  wifi.setmode(wifi.STATION)
  wifi.sta.config("hessemma","isabellaphess")
  wifi.sta.connect()
 
end


function main() 
  setup(0xFFFF)
  setup_wifi()
end

main()

