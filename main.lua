-- Constants
local CHECKS_PER_FRAME = 10

local target
if lovr.getOS() == "Android" then
	target = "/sdcard/lovr-dev/" .. lovr.android.getApplicationId()
else
	target = arg[1]
end
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
--for i, v in pairs(package.loaded) do print(i,v) end print("done")

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
					for _=1,CHECKS_PER_FRAME do
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

	-- Need to attempt to wrap errhand twice-- first time to catch errors in main.lua
	local loadTimeErrhand = makeWatchWrapper(lovr.errhand, "errhand")
	lovr.errhand = loadTimeErrhand

	package.loaded.main = nil
	require 'main'

	lovr.run = makeWatchWrapper(lovr.run, "run")
	if loadTimeErrhand ~= lovr.errhand then -- Second errhand wrap only needed if main.lua has an errhand
		lovr.errhand = makeWatchWrapper(lovr.errhand, "errhand (modded)")
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
