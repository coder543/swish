function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function init()
	local hfile = io.open("ncurses.hh", "rb")
	local hfilecontent = hfile:read("*all")
	hfile:close()
	ffi = require("ffi")
	ffi.cdef(hfilecontent)
	nc = ffi.load("ncurses")
	termwin = nc.initscr()
	commander = require("commander")
	commander.init()
	nc.noecho()
	-- walktree(commander.commands, "--")
end

-- function walkargtree(tree, marker)
-- 	if next(tree) == nil then 
-- 		return
-- 	end
-- 	print(marker:sub(1, -3) .. " table:")
-- 	for k,v in pairs(tree) do
-- 		if type(v) == "table" then
-- 			-- print(marker .. " " .. "table:")
-- 			walkargtree(v, marker .. "--")
-- 		else
-- 			print(marker .. " " .. k .. " " .. v)
-- 		end
-- 	end
-- end

-- function walktree(tree, marker)
-- 	for i,v in ipairs(tree) do
-- 		print(marker .. " name" .. " " .. v.name)
-- 		print(marker .. " description" .. " " .. v.description)
-- 		print(marker .. " func" .. " " .. tostring(v.func))
-- 		-- print(marker .. " args" .. " " .. "table:")
-- 		walkargtree(v.args, marker .. "--")
-- 	end
-- end

function getenter()
	local cur = nc.getch()
	nc.printw("" .. cur)
	while not (cur == string.byte("\n") or cur == 127) do
		cur = nc.getch()
		nc.printw("" .. cur)
	end
	if (cur == 127) then
		nc.printw("backspace!")
		return false
	else
		nc.printw("\n")
		return true
	end
end

-- accepts an autocomplete dictionary,
-- just an array of acceptable words
function getword(acdict)
	local commandstr = ""
	local curDict = {}
	while true do
		local nchar = nc.getch()

		compstring = commandstr
		if nchar == 127 then
			commandstr = string.sub(commandstr,1,-2)
			local curx = nc.getcurx(termwin) - 1
			if curx < 0 then
				curx = 0
			end
			nc.wmove(termwin, nc.getcury(termwin), curx)
			nc.wdelch(termwin)
		else
			compstring = compstring .. string.char(nchar)
		end
		-- nc.printw("" .. nchar)

		curDict = {}
		for i,v in ipairs(acdict) do
			if (v:starts(compstring)) then
				curDict[#curDict+1] = v
			end
		end
		if #curDict == 1 then
			nc.printw(string.sub(curDict[1], #commandstr + 1))
			return curDict[1]
		elseif #curDict > 1 then
			if nchar ~= 127 then
				nc.printw(string.char(nchar))
				commandstr = commandstr .. string.char(nchar)
			end
		end

	end
	return commandstr
end

function inputloop()
	local command
	while true do
		nc.printw("# ")
		nc.refresh()
		command = getword({"hello", "exit", "extreme"})
		if (getenter() == false) then
			local curx = nc.getcurx(termwin) - #command
			nc.wmove(termwin, nc.getcury(termwin), curx)
			local erase_i = 0
			while erase_i < #command do
				nc.printw(" ")
			end
			nc.wmove(termwin, nc.getcury(termwin), curx)
			command = ""
		end
		nc.refresh()
		if command == "exit" then
			break
		end
	end
end

function cleanup()
	nc.endwin()
end

init()
inputloop()
cleanup()