uart.setup(0, 9600, 8, uart.PARITY_NONE, uart.STOPBITS_1, 1)
print("Setup UART for 9600 8n1")
print("Initializing sprinkler...")
tmr.alarm(0, 100, tmr.ALARM_SINGLE, function()
	dofile('sprinkler.lua')
end