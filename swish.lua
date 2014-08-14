-- check if a string starts with a substring
function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function table.contains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
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

-- waits until enter key is pressed, ignoring all other input
function getenter()
	local cur = nc.getch()
	-- nc.printw("" .. cur)
	while not (cur == string.byte("\n") or cur == 127) do
		cur = nc.getch()
		-- nc.printw("" .. cur)
	end
	if cur == 127 then
		return false
	else
		nc.printw("\n")
		return true
	end
end

-- waits until space key is pressed, ignoring all other input
function getspace()
	local cur = nc.getch()
	-- nc.printw("" .. cur)
	while not (cur == string.byte(" ") or cur == 127) do
		cur = nc.getch()
		-- nc.printw("" .. cur)
	end
	if cur == 127 then
		return false
	else
		nc.printw(" ")
		return " "
	end
end

-- waits until space key or enter key is pressed, ignoring all other input
function getenterorspace()
	local cur = nc.getch()
	-- nc.printw("" .. cur)
	while not (cur == string.byte(" ") or cur == string.byte("\n") or cur == 127) do
		cur = nc.getch()
		-- nc.printw("" .. cur)
	end
	if cur == 127 then
		return false
	elseif cur == string.byte(" ") then
		nc.printw(" ")
		return " "
	elseif cur == string.byte("\n") then
		nc.printw("\n")
		return "\n"
	end
end

-- accepts an autocomplete dictionary,
-- just an array of acceptable words
function getword(acdict)
	local commandstr = ""
	local curDict = {}
	local arbNum = table.contains(acdict, "<number>")
	local arbStr = table.contains(acdict, "<string>")
	while true do
		local nchar = nc.getch()

		compstring = commandstr
		if nchar == 127 then
			if #commandstr > 0 then
				commandstr = string.sub(commandstr,1,-2)
				local curx = nc.getcurx(termwin) - 1
				if curx < 0 then
					curx = 0
				end
				nc.wmove(termwin, nc.getcury(termwin), curx)
				nc.wdelch(termwin)
			else
				return false
			end
		elseif nchar == string.byte("<") then
			-- special string detected, ignore	
			nchar = 127
		else
			compstring = compstring .. string.char(nchar)
		end
		-- nc.printw("" .. nchar)
		if arbStr == true then
			if nchar == string.byte(" ") then
				break
			elseif nchar ~= 127 and nchar ~= string.byte("\n") then
				nc.printw(string.char(nchar))
				commandstr = commandstr .. string.char(nchar)
			end
		elseif arbNum == true then
			if nchar >= string.byte("0") and nchar <= string.byte("9") then
				nc.printw(string.char(nchar))
				commandstr = commandstr .. string.char(nchar)
			elseif nchar == string.byte(" ") then
				break
			end
		else
			curDict = {}
			for i,v in ipairs(acdict) do
				if v:starts(compstring) then
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
	end
	return commandstr
end

function getcmdwords(curcommand)
	local curspot = commander.commands
	local found = false
	local lastHelp = ""
	for i=1,#curcommand do
		for j,v in ipairs(curspot) do
			if curcommand[i] == v.name then
				curspot = v.args
				lastHelp = v.description
				found = true
			end
		end
		if not found then
			if curcommand[i] == nil then
				nc.printw("Nil command string passed!\n")
			else
				nc.printw("Error, invalid command string! " .. #curcommand .. "\n")
			end
			return {}, false, "", true
		end
	end
	local returnwords = {}
	local canReturn = false
	for i,v in ipairs(curspot) do
		if v.name == "<cr>" then
			canReturn = true
		else
			returnwords[#returnwords+1] = v.name
		end
	end
	return returnwords, canReturn, lastHelp, false
end

function eraseLastWord(curcommand)
	-- let's erase the last word
	local curx = nc.getcurx(termwin) -- calculate cursor location to location - word length
	local erase_i = 0 -- loop counter to keep up with erasure
	while erase_i < #curcommand[#curcommand] do -- loop until erased
		nc.wmove(termwin, nc.getcury(termwin), curx - erase_i - 1) -- set the cursor location
		nc.wdelch(termwin) -- delete the character
		erase_i = erase_i + 1
	end
	nc.refresh()
	table.remove(curcommand, #curcommand) -- remove last word
end

function clearHelpText(ymod)

	local cury = nc.getcury(termwin) + 1 - ymod -- calculate cursor location to location + one line
	local curx = nc.getcurx(termwin)
	nc.wmove(termwin, cury, 0) -- set the cursor location
	nc.wclrtoeol(termwin)
	nc.wmove(termwin, cury + 1, 0) -- set the cursor location
	nc.wclrtoeol(termwin)
	nc.wmove(termwin, cury - 1 + ymod, curx)

end

function showHelp(command, nextwords, lastHelp, canReturn)
	-- now let's rewrite the help text
	local cury = nc.getcury(termwin) + 1 -- calculate cursor location to location + one line
	local curx = nc.getcurx(termwin) -- remember current x location
	nc.wmove(termwin, cury, 0) -- set the cursor location to beginning of help box
	if #command > 0 then
		nc.printw("| arguments: ")
	else
		nc.printw("| commands: ")
	end
	-- now, we're going to write out the list of accepted words
	-- first, handle the special case of canReturn
	if canReturn or #nextwords == 0 then
		nc.printw("<cr> ")
	end
	-- next, loop over all of the autocorrect words
	for i,v in ipairs(nextwords) do
		nc.printw(v .. " ") -- and print them
	end
	if #command > 0 then
		nc.printw("\n| " .. command[#command] .. ": " .. lastHelp .. "\n") -- print command help text
	end
	nc.wmove(termwin, cury-1, curx) -- reset the cursor location where we found it
end

-- this function is responsible for all high level logic in swish
function docommand()
	local command = {} -- this will be an array of all words in the command
	nc.printw("# ") -- let's print a prompt
	nc.refresh() -- refresh the screen
	local index = 1 -- current index in command array
	while true do -- loop infinitely, receiving more arguments for the command
		local nextwords, canReturn, lastHelp, err = getcmdwords(command) -- get autocorrect options
		if err == true then -- there was some kind of error, abort! abort!
			os.exit()
		end
		if #nextwords < 1 then -- if we don't have any autocorrect words, we must be at the end of a command string
			clearHelpText(0) -- clear the help text
			showHelp(command, nextwords, lastHelp, canReturn)
			if getenter() == false then -- let's wait for enter keystroke, but if they hit backspace
				eraseLastWord(command) -- then erase the last word of the command
				nextwords, canReturn, lastHelp, err = getcmdwords(command) -- get autocorrect options
				showHelp(command, nextwords, lastHelp, canReturn)
			else -- otherwise, we're clear to execute the command
				-- callCommand(command) -- run it!
				clearHelpText(1) -- clear the help text
				return -- return and await next command
			end
		elseif command[index] ~= nil then -- if the command has already been specified
			clearHelpText(0) -- clear the help text
			showHelp(command, nextwords, lastHelp, canReturn)

			-- now it is time to wait for some whitespace
			local wsinput
			if canReturn == true then
				wsinput = getenterorspace()
			else
				wsinput = getspace()
			end
			if wsinput == false then -- false means they backspaced
				eraseLastWord(command)
				nextwords, canReturn, lastHelp, err = getcmdwords(command) -- get autocorrect options
				clearHelpText(0) -- clear the help text
				showHelp(command, nextwords, lastHelp, canReturn)
			elseif wsinput == " " then
				index = index + 1 -- increment the location in the command
			else -- otherwise, we're clear to execute the command
				-- callCommand(command) -- run it!
				clearHelpText(1) -- clear the help text
				return -- return and await next command
			end
		else -- show help for initial word (aka. command, not argument)
			clearHelpText(0) -- clear the help text
			showHelp(command, nextwords, lastHelp, canReturn)
		end

		command[index] = getword(nextwords, canReturn)
		if command[index] == false then
			command[index] = nil
			command[index - 1] = command[index - 1] .. " "
			index = index - 1
			eraseLastWord(command)
		end
	end
end

-- this function simply keeps swish ready to accept more commands
function inputloop()
	while true do
		docommand()
	end
end

-- cleanup swish and the terminal here	
function cleanup()
	nc.endwin() -- exit ncurses mode
end

init() -- call the init function
inputloop() -- then do an input loop while the user has input to give
cleanup() -- then cleanup

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