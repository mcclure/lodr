-- erase lodr from the arg array
arg[0] = require("target")
local argc = #arg
for i=1,argc do arg[i] = arg[i+1] end
