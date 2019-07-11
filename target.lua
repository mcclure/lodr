if lovr.getOS() == "Android" then
	local appId = lovr.filesystem.getApplicationId()
	if not appId then error("Failed to get the Android application ID of the loader app") end
	return "/sdcard/Android/data/"..appId.."/files/.lodr"
else
	return arg[1]
end
