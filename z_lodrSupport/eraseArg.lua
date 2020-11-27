-- lodr helper: erase lodr from the arg array
local alreadyRan = false
local target = require("z_lodrSupport.target")

return function()
	if not alreadyRan then
		alreadyRan = true
		arg[0] = target
		local argc = #arg
		for i=1,argc do arg[i] = arg[i+1] end
	end
end
