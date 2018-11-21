local target = require("target")

_lodrConfData = {}

if target then
	local hasProject = lovr.filesystem.mount(target, "tempConfDir")
	local hasConf = lovr.filesystem.isFile('tempConfDir/conf.lua')

	if hasConf then
		_lodrConfData.exists = true

		local oldConf = lovr.conf

		local function xpcallFailed(message)
			return {message, debug.traceback()}
		end

		local success, result = xpcall(
			function() return require("tempConfDir.conf") end,
			xpcallFailed
		)

		if success then
			local newConf = lovr.conf

			_lodrConfData.returned = result

			if newConf ~= oldConf then
				local newConfSuccess, newConfResult = xpcall(newConf, xpcallFailed)

				if newConfSuccess then
					function lovr.conf()
						return newConfResult
					end

					_lodrConfData.conf = newConfResult
				else
					_lodrConfData.failure = newConfResult
				end
			end
		else
			_lodrConfData.failure = result
		end
	end

	if hasProject then lovr.filesystem.unmount(target) end
end