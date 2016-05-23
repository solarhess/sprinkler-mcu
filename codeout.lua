latch_pin = 2

gpio.mode(latch_pin, gpio.OUTPUT)
gpio.write(latch_pin, gpio.LOW)
result = spi.setup(1, spi.MASTER, spi.CPOL_HIGH, spi.CPHA_LOW, 16, 0)
print(result)

while true do
  for i=0,7 do
  	local value1 = bit.lshift(1,i) -- Value1 goes to the last register in the chain
  	local value2 = bit.lshift(1,7-i)
    print(i)
   	spi.send(1, bit.bor(value1, bit.lshift(value2,8))) -- daisychained registers... value1 is the end of the chain, value2 is connected to 

    gpio.write(latch_pin, gpio.HIGH)
    gpio.write(latch_pin, gpio.LOW)
    tmr.wdclr();
    tmr.delay(100000);
    tmr.wdclr();
  end
end
