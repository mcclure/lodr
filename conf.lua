local target = require("_lodrSupport.target")
local timer = require("lovr.timer")

-- Special value for passing data to main.lua
_lodrConfData = {}

local confReturned

-- "Forget" we've been loaded so we can reload conf after changing the root directory
package.loaded.conf = nil

if target then
	-- Some lovr projects will have a conf.lua in addition to the main.lua.
	-- We need to temporarily load, execute, and unload this conf.lua *before* loading main.lua,
	-- Becuase conf.lua determines the set of modules visible to main.lua.
	local hasProject = lovr.filesystem.mount(target)
	local confPath = "/conf.lua"
	local hasConf = lovr.filesystem.isFile(confPath)

	local function unloadConf() -- Have to unload before continuing so lovr can find lodr's main.lua!
		lovr.filesystem.unmount(target)
	end

	if hasConf then
		_lodrConfData.exists = true

		-- This temporary wrapper is only to catch errors in conf.lua and lovr.conf().
		-- Note it assumes conf.lua creates no threads.
		local watched = {confPath, [confPath]=timer.getTime()}
		local makeWatchWrapper = require("_lodrSupport.makeWrapper")(watched, 10)
		local originalErrhand = lovr.errhand -- Store errhand from boot.lua
		local confErrhand = makeWatchWrapper(originalErrhand, "errhand (conf.lua)")

		-- Execute conf.lua
		require("_lodrSupport.eraseArg")
		lovr.errhand = confErrhand
		confReturned = require("conf")
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

				-- Late unmount-- Assume boot.lua always calls lovr.conf if it exists
				unloadConf() 
				return result
			end
		else
			unloadConf()
		end
	else
		unloadConf()
	end
end

-- Although we un-set package.loaded.conf earlier, it will be re-set with the value (if any) we return here.
return confReturned
