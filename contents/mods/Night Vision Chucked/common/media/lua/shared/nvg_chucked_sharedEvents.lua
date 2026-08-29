local compat = require "nvg_chucked_crossModCompat.lua"

-- Night Vision Googles [B41/B42MP]
--- TTAJ1bl4
-- Workshop ID: 3470491629
--- Mod ID: PNV
Events.OnGameBoot.Add(compat.PNV)

local batteryManager = require "nvg_chucked_batteryManager.lua"
if not isClient() then
    Events.OnTick.Add(batteryManager.tick)
end

local nvgCore = require "nvg_chucked_core.lua"
Events.OnGameStart.Add(nvgCore.getNVGTypes)