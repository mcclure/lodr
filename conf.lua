local target = require("target")
local timer = require("lovr.timer")

_lodrConfData = {}

if target then
	-- Some lovr projects will have a conf.lua in addition to the main.lua.
	-- We need to temporarily load, execute, and unload this conf.lua *before* loading main.lua,
	-- Becuase conf.lua determines the set of modules visible to main.lua.
	local hasProject = lovr.filesystem.mount(target, "/tempConfDir")
	local confPath = "/tempConfDir/conf.lua"
	local hasConf = lovr.filesystem.isFile(confPath)

	if hasConf then
		_lodrConfData.exists = true

		-- This temporary wrapper is only to catch errors in conf.lua and lovr.conf().
		-- Note it assumes conf.lua creates no threads,
		-- and note that calling require() from conf.lua may not work right.
		local watched = {confPath, [confPath]=timer.getTime()}
		local makeWatchWrapper = require("makeWrapper")(watched, 10)
		local originalErrhand = lovr.errhand -- Store errhand from boot.lua
		local confErrhand = makeWatchWrapper(originalErrhand, "errhand (conf.lua)")

		-- Execute conf.lua
		require "eraseArg"
		lovr.errhand = confErrhand
		local result = require("tempConfDir.conf")
		lovr.errhand = originalErrhand

		-- Did conf.lua define a lovr.conf?
		local newConf = lovr.conf
		_lodrConfData.confFunc = newConf

		if newConf then
			-- Leave a lovr.conf function around for boot.lua to execute after this file runs
			function lovr.conf(t)
				-- Execute lovr.conf()
				lovr.errhand = confErrhand
				local result = newConf(t)
				lovr.errhand = originalErrhand

				-- Save a copy of the conf table so lodr can access its own conf.lodr values
				_lodrConfData.conf = t
				return result
			end
		end
	end
end
