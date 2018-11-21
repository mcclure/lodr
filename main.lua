-- Nab data from conf
local confData = _lodrConfData
_lodrConfData = nil
local conf = confData and confData.conf and confData.conf.lodr
if conf then
	local function confFail(failed, why)
		if failed then
			confData.failure = {"The \"lodr\" table in your conf.lua contains an error:\n" .. why, ""}
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
				return false
			end
		end
		return true
	end
	confFail(checkType("checksPerFrame", "number"))
	and confFail(checkType("watch", "table"))
	and confFail(conf.watch and checkAllStrings(conf.watch), "conf.lodr.watch contained a non-string value"))
end

-- Constants
local checksPerFrame = conf and conf.checksPerFrame or 10

local target = require("target")

if not arg[0] then error("arg[0] missing-- this is impossible, something is wrong with this copy of lovr") end
if not target then error("Please specify a project for lodr to run on the command line") end

lovr.filesystem.unmount(arg[0]) -- Unload lodr

local hasProject, hasMain

function tryMount()
	hasProject = hasProject or lovr.filesystem.mount(target) -- Load target
	hasMain = lovr.filesystem.isFile('main.lua')
end
tryMount()

--print("main?", hasMain)
for i, v in pairs(package.loaded) do print(i,v) end print("done")

local watched = {}
local watchtimes = {}

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
	recursiveWatch("/")
	if not confData.exists then
		table.insert(watched, "/conf.lua")
		watchtimes["/conf.lua"] = lovr.timer.getTime()
	end

	local function makeWatchWrapper(wrappedFunc, wrapTag)
		return function(...)
			local loop = wrappedFunc(...)
			local lastTimeRollover = lovr.timer.getTime()
			local watchedc = #watched
			local watchiter = watchedc+1

			return function(...)
				-- Check individual files no more than once a second. Check no more than 10 files per frame
				local getTime = lovr.timer.getTime()
				local rollover = getTime > lastTimeRollover + 1
				if (watchiter <= watchedc or rollover) then
					if watchiter > watchedc then watchiter = 1 end
					for _=1,checksPerFrame do
						if watchiter > watchedc then break end

						local path = watched[watchiter]
						local lastModified = lovr.filesystem.getLastModified(path)
						--print(wrapTag, watchiter,_, path, watchtimes[path], lastModified)
						if lastModified then -- This can be false if a file is deleted
							if not watchtimes[path] then watchtimes[path] = lastModified
							elseif watchtimes[path] < lastModified then return "restart" end
						end

						watchiter = watchiter + 1
					end 
				end
				if rollover then lastTimeRollover = getTime end

				return loop(...)
			end
		end
	end

	if confData.failure then
		lovr.run = makeWatchWrapper(
			function() return lovr.errhand(confData.failure[1], confData.failure[2]) end,
			"conf error"
		)
	else
		-- Need to attempt to wrap errhand twice-- first time to catch errors in main.lua
		local loadTimeErrhand = makeWatchWrapper(lovr.errhand, "errhand")
		lovr.errhand = loadTimeErrhand

		package.loaded.main = nil
		package.loaded.conf = confData.returned
		require 'main'

		lovr.run = makeWatchWrapper(lovr.run, "run")
		if loadTimeErrhand ~= lovr.errhand then -- Second errhand wrap only needed if main.lua has an errhand
			lovr.errhand = makeWatchWrapper(lovr.errhand, "errhand (modded)")
		end
	end
else
	local message, width, font, pixelDensity, lastTimeRollover

	function resetMessage()
		message = "The directory\n" .. target .. "\n"
		if hasProject then
			message = message .. "doesn't exist."
		else
			message = message .. "does not contain a main.lua."
		end
		if lovr.getOS() == "Android" then
			message = message .. "\n\nYou can upload a " .. (hasProject and "" or "fixed ")
			                  .. "project with:\nadb push your_directory_name " .. target
		else
			message = message .. "\n\nPls fix"
		end
		width = font:getWidth(message, .55 * pixelDensity)
	end

	function lovr.load()
		lastTimeRollover = lovr.timer.getTime()
		font = lovr.graphics.getFont()
		pixelDensity = font:getPixelDensity()
		lovr.graphics.setBackgroundColor(.105, .098, .137) -- look like boot.lua errhand
  		lovr.graphics.setColor(.863, .863, .863)
		resetMessage()
	end

	function lovr.update()
		local getTime = lovr.timer.getTime()
		if lastTimeRollover and getTime > lastTimeRollover + 1 then
			tryMount()
			if hasMain then
				lastTimeRollover = nil
				lovr.event.quit("restart")
			else
				lastTimeRollover = getTime
				resetMessage()
			end
		end
	end

	function lovr.draw()
    	lovr.graphics.print(message, -width / 2, 0, -20, 1, 0, 0, 0, 0, .55 * pixelDensity, 'left')
	end
end -- TODO: ConfError, not hasMain
