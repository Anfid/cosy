---------------------------------------------------------------------------
--- System monitoring and control module for cosy
--
-- @module system
---------------------------------------------------------------------------

local system = {
    audio  = require("cosy.system.audio"),
    status = require("cosy.system.status"),
}

return system
