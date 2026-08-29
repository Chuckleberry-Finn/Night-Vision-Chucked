local nvg = require "nvg_chucked_nvg.lua"
Events.OnCreatePlayer.Add(nvg.updateScreenBounds)
Events.OnResolutionChange.Add(nvg.updateScreenBounds)
Events.OnGameStart.Add(nvg.init)
Events.OnPlayerUpdate.Add(nvg.aimingWithNVGScope)
Events.OnKeyPressed.Add(nvg.onKeyPressed)

local inventoryBar = require "nvg_chucked_inventoryBar.lua"
Events.OnGameStart.Add(inventoryBar.init)