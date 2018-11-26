if lovr.getOS() == "Android" then
	local android = require("lovr.android")
	if not android then error("Can't load android module. Something is wrong with this copy of lovr") end
	local appId = android.getApplicationId()
	if not appId then error("Failed to get the Android application ID of the loader app") end
	return "/sdcard/Android/data/"..appId.."/files"
else
	return arg[1]
end
