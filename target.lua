if lovr.getOS() == "Android" then
	local appDataDir = lovr.filesystem.getAppdataDirectory()
	if not appDataDir then error("Failed to get the Android application data directory of the loader app") end
	return appDataDir .. "/.lodr"
else
	return arg[1]
end
