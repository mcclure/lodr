local target = require("target")
local timer = require("lovr.timer")

_lodrConfData = {}

if target then
	local hasProject = lovr.filesystem.mount(target, "/tempConfDir")
	local confPath = "/tempConfDir/conf.lua"
	local hasConf = lovr.filesystem.isFile(confPath)

	if hasConf then
		_lodrConfData.exists = true

		local watched = {confPath, confPath=timer.getTime()}
		local makeWatchWrapper = require("makeWrapper")(watched, 10)
		local originalErrhand = lovr.errhand
		local confErrhand = makeWatchWrapper(lovr.errhand, "errhand (conf.lua)")

		lovr.errhand = confErrhand
		local result = require("tempConfDir.conf")
		lovr.errhand = originalErrhand

		local newConf = lovr.conf
		_lodrConfData.confFunc = newConf

		if newConf then
			function lovr.conf(t)
				lovr.errhand = confErrhand
				local result = newConf(t)
				lovr.errhand = originalErrhand

				_lodrConfData.conf = t
				return result
			end
		end
	end
end
