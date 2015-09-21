function module.command(args)

	local action = table.remove(args, 1);
	
	if not action then -- Default, list registered users
	
		local data_path = CFG_DATADIR or "data";
		
		if not pcall(require, "luarocks.loader") then
			pcall(require, "luarocks.require");
		end
		
		local lfs = require "lfs";
		
		function decode(s)
			return s:gsub("%%([a-fA-F0-9][a-fA-F0-9])", function (c)
				return string.char(tonumber("0x"..c));
			end);
		end
		
		for host in lfs.dir(data_path) do
			local accounts = data_path.."/"..host.."/accounts";
			if lfs.attributes(accounts, "mode") == "directory" then
				for user in lfs.dir(accounts) do
					if user:sub(1,1) ~= "." then
						print(decode(user:gsub("%.dat$", "")).."@"..decode(host));
					end
				end
			end
		end
	elseif action == "--connected" then -- List connected users
		local socket = require "socket";
		local conn = assert(socket.connect("localhost", 5582)); -- TODO: check config for port
		repeat until conn:receive() == "";
		conn:send("c2s:show()\n");
		conn:settimeout(1); -- Only hit in case of failure
		repeat local line = conn:receive()
			if not line then break; end
			local jid = line:match("^|    (.+)$");
			if jid then
				jid = jid:gsub(" %- (%w+%(%d+%))$", "\t%1");
				print(jid);
			elseif line:match("^| OK:") then
				return 0;
			end
		until false;
	end
	return 0;
end
