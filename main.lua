-- Nab data from conf
local confData = _lodrConfData
_lodrConfData = nil
local conf = confData.conf and confData.conf.lodr
local confFailure
if conf then
	local function confFail(failed, why)
		if failed then
			confFailure = "The \"lodr\" table in your conf.lua contains an error:\n" .. why
			conf = nil
		end
		return not failed
	end
	local function checkType(f, ty)
		return conf[f] and type(conf[f]) ~= ty, "conf.lodr."..f.." must be a "..ty
	end
	local function checkAllStrings(t)
		for _,v in ipairs(t) do
			if type(v) ~= "string" then
				return true
			end
		end
		return false
	end
	local _ = confFail(checkType("checksPerFrame", "number"))
	      and confFail(checkType("watch", "table"))
	      and confFail(conf.watch and checkAllStrings(conf.watch), "conf.lodr.watch contained a non-string value")
end

-- Because of conf tomfoolery, all lovr packages except filesystem need to be manually required
local timer = require("lovr.timer")

-- Constants
local checksPerFrame = conf and conf.checksPerFrame or 10

local target = require("target")

if not arg[0] then error("arg[0] missing-- this is impossible, something is wrong with this copy of lovr") end
if not target then error("Please specify a project for lodr to run on the command line") end

local watched = {}
local makeWatchWrapper = require("makeWrapper")(watched, checksPerFrame)

lovr.filesystem.unmount(target) -- Speculatively unload tempConfDir/ from conf.lua
lovr.filesystem.unmount(arg[0]) -- Unload lodr

local hasProject, hasMain

function tryMount()
	hasProject = hasProject or lovr.filesystem.mount(target) -- Load target
	hasMain = lovr.filesystem.isFile('main.lua')
end
tryMount()

--print("main?", hasMain)
--for i, v in pairs(package.loaded) do print(i,v) end print("done")

local function recursiveWatch(path)
	if lovr.filesystem.isDirectory(path) then
		for i,filename in ipairs(lovr.filesystem.getDirectoryItems(path)) do
			if not filename:match('^%.') then
				recursiveWatch((path ~= "/" and path or "") .. "/" .. filename)
			end
		end
	else
		table.insert(watched, path)
	end
end

-- TODO: Because lodr has no conf.lua, all modules will be loaded, regardless of what target requested
-- TODO: if not hasMain add main to watched and run anwyay
if hasMain then
	-- TODO: Watching all files has good coverage but may not be the most efficient?
	if not (conf and conf.watch) then
		recursiveWatch("/")
		if not confData.exists then
			table.insert(watched, "/conf.lua")
		end
	else
		for _,v in ipairs(conf.watch) do
			table.insert(watched, v)
		end
	end

	if confFailure then
		lovr.run = makeWatchWrapper(
			function() return lovr.errhand(confFailure, "") end,
			"conf error"
		)
	else
		-- Need to attempt to wrap errhand twice-- first time to catch errors in main.lua
		local loadTimeErrhand = makeWatchWrapper(lovr.errhand, "errhand")
		lovr.errhand = loadTimeErrhand

		if confData.confFunc then lovr.conf = confData.confFunc end

		-- Erase all evidence we ever existed: Packages
		package.loaded.main = nil
		package.loaded.target = nil
		package.loaded.makeWrapper = nil
		package.loaded.conf = package.loaded['tempConfDir.conf']
		package.loaded['tempConfDir.conf'] = nil

		-- Erase all evidence we ever existed: Args
		arg[0] = target
		local argc = #arg
		for i=1,argc do arg[i] = arg[i+1] end

		-- Run main
		require 'main'

		lovr.run = makeWatchWrapper(lovr.run, "run")
		if loadTimeErrhand ~= lovr.errhand and not (conf and conf.overrideErrhand) then -- Second errhand wrap only needed if main.lua has an errhand
			lovr.errhand = makeWatchWrapper(lovr.errhand, "errhand (modded)")
		end
	end
else
	local graphics = require("lovr.graphics")
	local event = require("lovr.event")
	local message, width, font, pixelDensity, lastTimeRollover

	function resetMessage()
		local lastMessage = message

		-- This is kind of annoying actually
		local atLeastOneFile, firstFileIsDirectory, atLeastTwoFiles
		if hasProject then
			for _,filename in ipairs(lovr.filesystem.getDirectoryItems("/")) do
				if not filename:match('^%.') then
					if atLeastOneFile then
						atLeastTwoFiles = true
						break
					else
						atLeastOneFile = true
						firstFileIsDirectory = lovr.filesystem.isDirectory("/" .. filename)
					end
				end
			end
		end

		message = "The directory\n" .. target .. "\n"
		if not hasProject then
			message = message .. "doesn't exist."
		elseif not atLeastOneFile then
			message = message .. "is empty."
		else
			message = message .. "does not contain a main.lua."
		end
		if lovr.getOS() == "Android" then
			message = message .. "\n\To upload a " .. ((not hasProject or not atLeastOneFile) and "" or "fixed ")
			                  .. "project,\ncd to your project directory and run:\n"
			                  .. "adb push --sync . " .. target
			-- Detect, and warn the user about, a completely miserable UX limitation in adb push
			if firstFileIsDirectory and not atLeastTwoFiles then
				message = message .. "\n\n-- OKAY, I'M REALLY SORRY, BUT:"
				                  .. "\nDid you try to adb push a directory?"
				                  .. "\nThe thing you \"adb push\" has to end with a \".\""
				                  .. "\nSo this will work:"
				                  .. "\nadb push YOURDIRECTORY/. " .. target
				                  .. "\nBut this won't:"
				                  .. "\nadb push YOURDIRECTORY " .. target
			end
		else
			message = message .. "\n\nPlz fix"
		end
		width = font:getWidth(message, .55 * pixelDensity)
		
		if message ~= lastMessage then print(message) end
	end

	function lovr.load()
		lastTimeRollover = timer.getTime()
		font = lovr.graphics.getFont()
		pixelDensity = font:getPixelDensity()
		graphics.setBackgroundColor(.105, .098, .137) -- look like boot.lua errhand
  		graphics.setColor(.863, .863, .863)
		resetMessage()
	end

	function lovr.update()
		local getTime = timer.getTime()
		if lastTimeRollover and getTime > lastTimeRollover + 1 then
			tryMount()
			if hasMain then
				lastTimeRollover = nil
				event.quit("restart")
			else
				lastTimeRollover = getTime
				resetMessage()
			end
		end
	end

	function lovr.draw()
    	graphics.print(message, -width / 2, 0, -20, 1, 0, 0, 0, 0, .55 * pixelDensity, 'left')
	end
end -- TODO: ConfError, not hasMain
