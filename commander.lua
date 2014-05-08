local P = {} -- package
if _REQUIREDNAME == nil then
	commander = P
else
	_G[_REQUIREDNAME] = P
end
setfenv(1, P)

commands = {}

function doNothing(...) end

function createArg(name, description, args)
	local comarg = {}
	comarg.name = name
	comarg.description = description
	comarg.args = args
	return comarg
end

function addCommand(name, description, func, args)
	local com_index = #commands+1
	commands[com_index] = {}
	commands[com_index].name = name
	commands[com_index].description = description
	commands[com_index].func = func
	commands[com_index].args = args
end

function init()
	-- return "parsed!"
	addCommand("ip", "configure the internet", doNothing,{
		createArg("stat", "status of the internet", {}),
		createArg("enable", "enable the internet", {}),
		createArg("shut", "shutdown the internet", {}),
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
			createArg("<string>", "the IP address or domain name of the targeted website", {})
		}),
		createArg("restart", "reboot the internet", {
			createArg("<cr>", "reboot the internet now", {}),
			createArg("<number>", "specify in how many seconds the internet should be rebooted", {})
		})
	})
end

return P