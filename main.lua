local CHECKS_PER_FRAME = 10

local target = arg[1] -- TODO: Check Android
if not arg[0] then error("arg[0] missing-- this is impossible, something is wrong with this copy of lovr") end
if not target then error("Please specify a project for lodr to run on the command line") end
lovr.filesystem.unmount(arg[0]) -- Unload lodr
lovr.filesystem.mount(target) -- Load target

local hasMain = lovr.filesystem.isFile('main.lua')

print("main?", hasMain)
--for i, v in pairs(package.loaded) do print(i,v) end print("done")

local watched = {}
local watchtimes = {}

local function recursiveWatch(path)
	if lovr.filesystem.isDirectory(path) then
		if not path:match('^%.') then
			recursiveWatch(path)
		end
	else
		table.insert(watched, path)
	end
end

-- TODO: Because lodr has no conf.lua, all modules will be loaded, regardless of what target requested
-- TODO: if not hasMain add main to watched and run anwyay
if hasMain then
	-- TODO: Watching all files has good coverage but may not be the most efficient?
	recursiveWatch(target)

	package.loaded.main = nil
	require 'main'
	local run = lovr.run
	lovr.run = function()
		local loop = run()
		local lastTimeRollover = lovr.timer.getTime()
		local watchedc = #watched
		local watchiter = watchedc+1

		return function()
			-- Check individual files no more than once a second. Check no more than 10 files per frame
			local getTime = lovr.timer.getTime()
			local rollover = getTime > lastTimeRollover + 1
			if (watchiter <= watchedc or rollover) then
				if watchiter > watchedc then watchiter = 1 end
				for _=1,CHECKS_PER_FRAME do
					if watchiter > watchedc then break end

					local path = watched[watchiter]
					local lastModified = lovr.filesystem.getLastModified(path)
					print(watchiter,_, path, watchtimes[path], lastModified)
					if not watchtimes[path] then watchtimes[path] = lastModified
					elseif watchtimes[path] < lastModified then return "restart" end

					watchiter = watchiter + 1
				end 
			end
			if rollover then lastTimeRollover = getTime end

			return loop()
		end
	end
end -- TODO: ConfError, not hasMain
