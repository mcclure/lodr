if lovr.getOS() == "Android" then
	return "/sdcard/lovr-dev/" .. lovr.android.getApplicationId()
else
	return arg[1]
end
