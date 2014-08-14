-- lua package boilerplate, ignore this
local P = {}
if _REQUIREDNAME == nil then
	commander = P
else
	_G[_REQUIREDNAME] = P
end
setfenv(1, P)
-- done ignoring

-- the full set of commands available
commands = {}

-- a temporary placeholder for the concept of having a callback on 
-- execution of a command
function doNothing(...) end

-- this function will create an argument to a command
function createArg(name, description, args)
	local comarg = {}
	comarg.name = name
	comarg.description = description
	comarg.args = args
	return comarg
end

-- this function will create a command
function addCommand(name, description, func, args)
	local com_index = #commands+1
	commands[com_index] = {}
	commands[com_index].name = name
	commands[com_index].description = description
	commands[com_index].func = func
	commands[com_index].args = args
end

-- this function initializes the list of commands by creating each one
function init()
	-- by calling add command and daisy chaining as many 'createArg' calls as we want into the 'args' table
	-- for a command, we can create any number of variations
	-- ip supports
	-- ip stat
	-- ip enable
	-- ip shut
	-- ip set <number>
	-- which includes things like
	-- ip set 11234
	-- ip set 24152543321
	-- ip set 25
	-- obviously a macro could be created for IP address that just accepts proper IP addresses
	addCommand("ip", "configure the internet", doNothing,{
		createArg("stat", "status of the internet", {}),
		createArg("enable", "enable the internet", {}),
		createArg("shut", "shutdown the internet", {}),
		createArg("send", "send the IPs", {}),
		createArg("set", "set the internet's IP address", {
			createArg("<number>", "an IP address", {})
		})
	})
	addCommand("sip", "manipulate the IP phone system", doNothing, {
		createArg("user", "do things to all users", {
			createArg("registration", "list all users registered", {})
		}),
		createArg("stop", "stop all phone calls", {})
	})
	addCommand("internet", "alter the internet", doNothing, {
		createArg("website", "disable a website", {
			createArg("<string>", "the IP address or domain name of the targeted website", {}) -- <string> is any no-whitespace word
		}),
		createArg("restart", "reboot the internet", {
			createArg("<cr>", "reboot the internet now", {}), -- <cr> means you could early-terminate this command with a stroke of the enter key
			createArg("<number>", "specify in how many seconds the internet should be rebooted", {})
		})
	})
end

return P