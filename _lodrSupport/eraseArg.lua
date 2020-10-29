-- lodr helper: erase lodr from the arg array
-- this is intentionally done at the top level and not in a function to ensure it happens only once

arg[0] = require("_lodrSupport.target")
local argc = #arg
for i=1,argc do arg[i] = arg[i+1] end
