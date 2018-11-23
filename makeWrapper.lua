return function(watched, checksPerFrame, recognizeFileAppear)
	return function(wrappedFunc, wrapTag)
		return function(...)
			local loop = wrappedFunc(...)
			local lastTimeRollover = lovr.timer.getTime()
			local watchedc = #watched
			local watchiter = watchedc+1
			local timer = require("lovr.timer")

			return function(...)
				-- Check individual files no more than once a second. Check no more than 10 files per frame
				local getTime = timer.getTime()
				local rollover = getTime and (getTime > lastTimeRollover + 1)
				if (not getTime or watchiter <= watchedc or rollover) then
					if watchiter > watchedc then watchiter = 1 end
					for _=1,checksPerFrame do
						if watchiter > watchedc then break end

						local path = watched[watchiter]
						local lastModified = lovr.filesystem.getLastModified(path)
						--print(wrapTag, watchiter,_, path, watchtimes[path], lastModified)
						if lastModified then -- This can be false if a file is deleted
							if not watched[path] then watched[path] = lastModified
							elseif (recognizeFileAppear and not lastModified)
								or watched[path] < lastModified then return "restart" end
						end

						watchiter = watchiter + 1
					end
				end
				if rollover then lastTimeRollover = getTime end

				return loop(...)
			end
		end
	end
end