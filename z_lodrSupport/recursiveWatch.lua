-- lodr helper: function that fills out the "watched" table

local function startsWith(s, prefix)
	return s:sub(1, #prefix) == s
end

return function(watched, watchRealpath) 
	local function recursiveWatch(path)
		if lovr.filesystem.isDirectory(path) then
			for i,filename in ipairs(lovr.filesystem.getDirectoryItems(path)) do
				if not startsWith(filename, ".") then -- Skip hidden files/directories
					recursiveWatch((path ~= "/" and path or "") .. "/" .. filename)
				end
			end
		else
			-- Files in the save directory were written *by* the program; if they change, that isn't a program change.
			-- So we don't accidentally watch files in the save directory, verify every filepath against the true file root. 
			if startsWith(lovr.filesystem.getRealDirectory(path), watchRealpath) then
				table.insert(watched, path)
			end
		end
	end

	return recursiveWatch
end
