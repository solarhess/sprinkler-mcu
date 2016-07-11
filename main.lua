---------------------------------
-- main.lua
--
-- Author: Jonathan Hess
-- Initializes the server and other modules to run the sprinkler system

require('webserver')
-- require('valves')


function setup_time()
	net.dns.resolve("time.apple.com", function(sk, ip)
	    if (ip == nil) then
	    	print("DNS fail!") 
	    else
			sntp.sync(ip,
			  function(sec,usec,server)
			    print('Current Time', sec, usec, server)
			    rtctime.set(sec,usec)
			  end,
			  function()
			   print('failed!')
			  end
			)
	    end
	end)
end


function setup_network() 
  wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(T) 
    print("\n\tSTA - GOT IP".."\n\tStation IP: "..T.IP.."\n\tSubnet mask: "..
    T.netmask.."\n\tGateway IP: "..T.gateway)
    mdns.register("sprinkler",{description="Sprinkler Control", service="http", port=80, location="Basement"})
    webserver.setup()
	setup_time()
	print("Webserver is running")
  end)

  wifi.setmode(wifi.STATION)
  wifi.sta.config("hessemma","isabellaphess")
  wifi.sta.connect()
 
end


function main()
	print("Initializing Sprinkler Controls")
	setup_network()
end

main()