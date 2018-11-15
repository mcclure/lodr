
local target = arg[1] -- TODO: Check Android
if arg[0] then lovr.filesystem.unmount(arg[0]) end -- Unload lodr
if arg[1] then lovr.filesystem.mount(arg[1]) end -- Load target

local hasMain = lovr.filesystem.isFile('main.lua')

print("main?", hasMain)
--for i, v in pairs(package.loaded) do print(i,v) end print("done")

-- TODO: Because lodr has no conf.lua, all modules will be loaded, regardless of what target requested
if hasMain then
	package.loaded.main = nil
	require 'main'
	local run = lovr.run
	lovr.run = function()
		local loop = run()
		return function()
			print("FRAME", lovr.timer.getTime())
			return loop()
		end
	end
end -- TODO: ConfError, not hasMain
