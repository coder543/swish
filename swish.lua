-- check if a string starts with a substring
function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

-- initializes swish
function init()
	local hfile = io.open("ncurses.hh", "rb") -- let's open up ncurses.hh
	local hfilecontent = hfile:read("*all") -- read it all into memory
	hfile:close() -- close the file
	ffi = require("ffi") -- import the LuaJIT ffi (foreign function interface)
	ffi.cdef(hfilecontent) -- declare all of our C interfaces based on ncurses.hh
	nc = ffi.load("ncurses") -- load the ncurses library (libncurses.so) into 'nc'
	termwin = nc.initscr() -- initialize the ncurses window
	commander = require("commander") -- import commander.lua as commander
	commander.init() -- initialize all of the commands
	nc.noecho() -- turn off echoing in ncurses (keystrokes only print if we print them)
	-- walktree(commander.commands, "--")
end

-- utility functions to walk a tree of commands
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

-- waits until enter key is pressed, ignoring all other input
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

-- this function is responsible for all high level logic in swish
function inputloop()
	local command
	while true do
		nc.printw("# ")
		nc.refresh()
		command = getword({"hello", "exit", "extreme"}) -- we really need to pass the current word in the commands dictionary
		if (getenter() == false) then -- false means they backspaced
			-- let's erase the last word
			local curx = nc.getcurx(termwin) - #command -- calculate cursor location to location - word length
			nc.wmove(termwin, nc.getcury(termwin), curx) -- set the cursor location
			local erase_i = 0 -- loop counter to keep up with erasure
			while erase_i < #command do -- loop until erased
				nc.printw(" ") -- erase each letter
			end
			nc.wmove(termwin, nc.getcury(termwin), curx) -- move back to the beginning of the now-erased word
			command = "" -- empty the word
		end
		nc.refresh() -- refresh the terminal (not always needed)
		if command == "exit" then
			break -- breaking the loop means ending the program
		end
	end
end

-- cleanup swish and the terminal here
function cleanup()
	nc.endwin() -- exit ncurses mode
end

init() -- call the init function
inputloop() -- then do an input loop while the user has input to give
cleanup() -- then cleanup

