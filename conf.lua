local target = require("target")
local timer = require("lovr.timer")

_lodrConfData = {}

if target then
	local hasProject = lovr.filesystem.mount(target, "/tempConfDir")
	local confPath = "/tempConfDir/conf.lua"
	local hasConf = lovr.filesystem.isFile(confPath)

	if hasConf then
		_lodrConfData.exists = true

		local oldConf = lovr.conf

		local watched = {confPath, confPath=timer.getTime()}
		local makeWatchWrapper = require("makeWrapper")(watched, 10, true)
		local originalErrhand = lovr.errhand
		lovr.errhand = makeWatchWrapper(lovr.errhand, "errhand (conf.lua)")

		local result = require("tempConfDir.conf")

		local newConf = lovr.conf

		_lodrConfData.returned = result

		if newConf ~= oldConf then
			local newConfResult = newConf()
			-- Turn on timer?

			function lovr.conf()
				return newConfResult
			end

			_lodrConfData.conf = newConfResult
		end

		lovr.errhand = originalErrhand
	end

	if hasProject then lovr.filesystem.unmount(target) end
end
