---SOFT PATCH TO AVOID ERRORS FROM GUNFIGHTER WHEN LACKING NVAPI INSTALLED
if not getActivatedMods():contains("NVAPI") then return nil end

local Control = require "NVAPI/ctrl/Control"
NVAPI_CONTROL_INSTANCE = NVAPI_CONTROL_INSTANCE or Control:new()
return NVAPI_CONTROL_INSTANCE