-- lodr helper creates a replacement for a built-in lovr function (like lovr.run or lovr.errhand),
-- which injects a check for changed files into the event loop.
local timer = require("lovr.timer")
local event = require("lovr.event")
return function(watched, checksPerFrame)
	return function(wrappedFunc, wrapTag)
		return function(...)
			local loop = wrappedFunc(...)
			local lastTimeRollover
			local watchedc = #watched
			local watchiter = watchedc+1
			local initialized = false

			return function(...)
				-- Check individual files no more than once a second. Check no more than 10 files per frame
				local getTime = timer.getTime()
				local rollover = not initialized or getTime > lastTimeRollover + 1
				if watchiter <= watchedc or rollover then
					if watchiter > watchedc then watchiter = 1 end
					local checks = initialized and checksPerFrame or watchedc
					for _=1,checks do
						if watchiter > watchedc then break end

						local path = watched[watchiter]
						local lastModified = lovr.filesystem.getLastModified(path)
						--print(wrapTag, watchiter,_, path, watchtimes[path], lastModified)
						if initialized then
							local had, have = watched[path] ~= nil, lastModified ~= nil
							if had ~= have or (had and have and watched[path] ~= lastModified) then
								event.restart()
							end
						else
							watched[path] = lastModified
						end
						
						watchiter = watchiter + 1
					end

					initialized = true
				end
				if rollover then lastTimeRollover = getTime end

				return loop(...)
			end
		end
	end
end