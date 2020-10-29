-- erase lodr from the arg array
arg[0] = require("_lodrSupport.target")
local argc = #arg
for i=1,argc do arg[i] = arg[i+1] end
