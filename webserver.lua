module("webserver", package.seeall) -- lua 5.1 style modules


local page_head_200 = 'HTTP/1.0 200 OK\r\nServer: NodeMCU on ESP8266\r\nContent-Type: text/html\r\n\r\n<!DOCTYPE HTML><html><head><meta name = "viewport" content = "width=device-width"></head><body>'

local page_foot = "</body></html>" 

local srv = nil
local handlers = {}

local function handler404(path)
    response = {"HTTP/1.0 404 NOT FOUND\r\nServer: NodeMCU on ESP8266\r\nContent-Type: text/html\r\n\r\n"} 
    response[#response + 1] = "<h1>404 Not Found "..path.."</h1><p><a href='/'>Home</a></p>"
    return response
end

function webserver.add_handler(pattern, handler_fn)
	handlers[pattern] = handler_fn
end

function webserver.setup()
  function handle_request(sck, req)
      _, _, method, path = string.find(req,"(\w+)%s(/%S*)%sHTTP")
      local response = nil
      
      if path ~= nil then
      	for pattern, handler_fn in pairs(handlers) do 
      		local pattern_result = {string.find(path, pattern)}
      		if #pattern_result > 0 then
			    print("GET",path,'200', pattern)
      			response = handler_fn(req, path, pattern_result)
      			if response ~= nil then
      				break
      			end
			end
      	end
      end

      if response == nil then
	    print("GET",path ,'404')
        response = handler404(path or '?')
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


webserver.add_handler("^/$", 
	function(path, req, pattern_params)
		response = {page_head_200}
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
        response[#response + 1] = page_foot
        return response
	end)

webserver.add_handler("^/off$", 
	function(path, req, pattern_params)
        -- turn_all_off()
        response = {page_head_200}
        response[#response + 1] = "<h1>Sprinkler Control</h1>"
        response[#response + 1] = "<p>All Off</p>"
        response[#response + 1] = "<p><a href='/'>Home</a></p>"
        response[#response + 1] = page_foot
        return response
	end)

webserver.add_handler( "^/(%d+)/(%d+)$", 
	function(path, req, pattern_params)
		if #pattern_params ~= 4 then
			return nil
		end

        local valve = pattern_params[3]
        local sec = pattern_params[4]
        if(valve ~= nil) then
          -- enable_sprinkler(tonumber(valve), tonumber(sec) * 1000)
          response = {page_head_200}
          response[#response + 1] = "<h1>Enabled Valve "
          response[#response + 1] = valve
          response[#response + 1] = " for "
          response[#response + 1] = sec
          response[#response + 1] = " seconds"
          response[#response + 1] = "</h1>"
          response[#response + 1] = "<p>Use GET /[valve index]/[seconds] to turn on a sprinkler for a period of seconds. eg GET /3/15 turns on valve 3 for 15 minutes</p>"
          response[#response + 1] = "<p><a href='/'>Home</a></p>"
          response[#response + 1] = "<p><a href='/'>Home</a></p>"
          response[#response + 1] = page_foot
	      return response
        end
        return nil
	end)