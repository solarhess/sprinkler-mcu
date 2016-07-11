--------------------------------------
-- shiftregisterout.lua
-- Author: Jonathan Hess
--
-- Allows you to control a chain of 2 8-bit 74hc595 shift registers
--
--
-- Wiring Connections for 74hc595
-- pin     GPIO #IO     595 pin     
-- srclk   14              11
-- rclk     4    2         12
-- ~oe      5    1         13
-- ser     13              14
-- 
module("shiftregisterout", package.seeall)

local latch_pin = 2 -- constant for latch pin
local oe_pin = 1 -- constant for OE pin

-----------------------
-- setup() Initializes the GPIO, resets to pinmask 
-- pinmask - a 2 byte number indicating the state of the 16 output pins
function shiftregisterout.setup(pinmask)
  gpio.mode(latch_pin, gpio.OUTPUT)
  gpio.write(latch_pin, gpio.LOW)
  gpio.mode(oe_pin, gpio.OUTPUT, gpio.PULLUP)
  result = spi.setup(1, spi.MASTER, spi.CPOL_HIGH, spi.CPHA_LOW, 16, 0)
  write(pinmask)
  shiftregisterout.output_enabled(false)
end

--------------------------
function shiftregisterout.output_enabled(enabled)
	if enabled then
    	gpio.write(oe_pin, gpio.LOW)
    else
    	gpio.write(oe_pin, gpio.HIGH)
    end
end

function shiftregisterout.write(pinmask)
    spi.send(1, pinmask) -- daisychained registers... value1 is the end of the chain, value2 is connected to gpio
    gpio.write(latch_pin, gpio.HIGH)
    gpio.write(latch_pin, gpio.LOW)
    shiftregisterout.output_enable(true)
end

return shiftregisterout