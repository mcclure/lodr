-- lodr helper figures out what directory it is we're supposed to be running
local system = lovr.system or require('lovr.system')
if system.getOS() == "Android" then
	lovr.filesystem.setIdentity("IGNORETHIS") -- This will be ignored and is to work around a bug in Lovr 0.14.
	local appId = lovr.filesystem.getIdentity()
	if not appId then error("Failed to get the Android application ID of the loader app") end
	return "/sdcard/Android/data/"..appId.."/files/.lodr"
else
	return arg[1] or false
end
