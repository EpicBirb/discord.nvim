local Presence = {
	config = {
		clientID = "1201359842766503946",
		ipcpath = nil
	},
	augroup = vim.api.nvim_create_augroup("discordrpc", {clear=true}),
	OPCodes = {
		HANDSHAKE = 0,
		FRAME = 1,
		CLOSE = 2,
		PING = 3,
		PONG = 4
	},
	ready = false,
	starttime = os.time()
}

-- https://github.com/iryont/lua-struct
-- modified for discord rpc
local unpack = table.unpack or _G.unpack
local function build(opcode, msg)
	local res, vars = {}, {opcode, string.len(msg)}
	for i=1,2 do
		local val, bytes = table.remove(vars, 1), {}
		for j=1,4 do
			table.insert(bytes, string.char(val%(2^8)))
			val = math.floor(val/(2^8))
		end
		table.insert(res, table.concat(bytes))
	end
	return table.concat(res)..msg
end
local function parse(buf)
	local vars, idx, val = {}, 1, 0
	for i=1,2 do
		val = 0
		for j=0,3 do
			val = val+string.byte(buf:sub(idx, idx))*(2^(j*8))
			idx = idx+1
		end
		table.insert(vars, math.floor(val))
	end
	table.insert(vars, buf:sub(idx, idx+math.floor(val-1)))
	return unpack(vars)
end

local function randuuid()
	return string.gsub(
		"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx", "x",
		function(_)
			math.randomseed(os.clock() * math.random())
			return string.format("%x", math.random(0, 15))
		end
	)
end

function Presence:disableDefaultEvents()
	vim.api.nvim_del_augroup_by_id(self.augroup)
end

function Presence:setup(cnf)
	self.config = vim.tbl_deep_extend("force", self.config, cnf or {})
end

function Presence:getIPCPath()
	if self.config.ipcpath ~= nil then
		return self.config.ipcpath
	end
	local initial = vim.loop.os_uname().sysname == "Windows_NT" and "\\\\.\\pipe\\discord-ipc-%s" or string.format("%s/discord-ipc-%%s", (os.getenv("XDG_RUNTIME_DIR") or os.getenv("TMPDIR") or os.getenv("TMP") or os.getenv("TEMP") or "/temp"):gsub("/$", ""))

	for pC=0,9 do
		if vim.uv.fs_stat(initial:format(pC)) then
			return initial:format(pC)
		end
	end
	return nil
end

function Presence:begin()
	if self.pipe and not self.pipe:is_closing() then
		print("Discord RPC is already running")
		return
	end
	self.pipe = vim.uv.new_pipe(false)
	local path = self:getIPCPath()
	if path == nil then
		return print("Discord pipe not found (exceeded 10 finds). Is discord running? use :DiscordConnect")
	end
	
	self.pipe:connect(path, function(err) self:onConnect(err) end)
end

function Presence:onConnect(err)
	print("Connected Discord RPC")
	self.pipe:read_start(function(err, chunk)
		if err then
			error(err)
		elseif chunk then
			local op, size, message = parse(chunk)
			if op == self.OPCodes.PING then
				return self:rawSend(self.OPCodes.PONG, message)
			elseif op == self.OPCodes.CLOSE then
				return self:disconnect()
			elseif op == self.OPCodes.FRAME then
				message = vim.json.decode(message)
				if message.evt == "READY" then
					self.ready = true
					return
				elseif message.evt == "ERROR" then
					error(string.format("Discord RPC replied with error %s: %s", message.data.code, message.data.message))
				end
			end
		else
			self.ready = false
			self.pipe:read_stop()
			self.pipe:close()
			print("Discord RPC Disconnected")
		end
	end)
	self:rawSend(self.OPCodes.HANDSHAKE, vim.json.encode({v = 1, client_id = self.config.clientID}))
end

function Presence:disconnect()
	self.ready = false
	print("Disconnecting from Discord RPC")
	self.pipe:shutdown()
	if not self.pipe:is_closing() then
    	self.pipe:close()
    end
end

function Presence:rawSend(opcode, payload)
	self.pipe:write(build(opcode, payload))
end

function Presence:send(cmd, payload)
	if self.ready == false then
		return
	end
	local message = vim.json.encode({
		cmd = cmd,
		args = payload,
		nonce = randuuid()
	})

	self.pipe:write(build(self.OPCodes.FRAME, message))
end

function Presence:setActivity(details, state, timestamps, assets, buttons)
	if details == nil then
		return self:send("SET_ACTIVITY", {pid=vim.uv.os_getpid()})
	end

	self:send("SET_ACTIVITY", {
		pid = vim.uv.os_getpid(),
		activity = {
			state = state,
			details = details,
			timestamps = timestamps,
			assets = assets,
			buttons = buttons,
		}
	})
end

vim.api.nvim_create_user_command("DiscordConnect", function(info)
	print("Connecting...")
	Presence:begin()
end, {})

vim.api.nvim_create_user_command("DiscordDisconnect", function(info)
	print("Disconnecting...")
	Presence:disconnect()
end, {})

vim.api.nvim_create_user_command("DiscordReconnect", function(info)
	print("Reconnecting...")
	Presence:disconnect()
	Presence:begin()
end, {})

vim.discordRPC = Presence
return Presence
