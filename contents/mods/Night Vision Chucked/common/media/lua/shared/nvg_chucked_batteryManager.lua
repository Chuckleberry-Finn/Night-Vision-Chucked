local nvgCore = require "nvg_chucked_core.lua"
local compat = require "nvg_chucked_crossModCompat.lua"

local batteryManager = {}

batteryManager.runtime = 30
batteryManager.batteryItemType = "Base.Battery"


function batteryManager.getDefaultBatteryWeight()
    local battery = instanceItem(batteryManager.batteryItemType)
    return battery and battery:getWeight() or 0.5
end


function batteryManager.refreshWeight(itemObj, batteryWeight)
    if batteryManager.hasBattery(itemObj) then
        itemObj:setActualWeight(itemObj:getWeight() + (batteryWeight or batteryManager.getDefaultBatteryWeight()))
    else
        itemObj:setActualWeight(itemObj:getWeight())
    end
    itemObj:setCustomWeight(true)
end


function batteryManager.hasAlternatePower(itemObj)
    return itemObj:getModData()["uiBattery_canUseGeneratorPower"] or false
end


function batteryManager.hasPower(itemObj)
    return (tonumber(itemObj:getModData()["uiBattery_batteryLevel"]) or 0) > 0
end


function batteryManager.hasBattery(itemObj)
    return itemObj:getModData()["uiBattery_battery"] or false
end


function batteryManager.getPowerLevel(itemObj)
    return itemObj:getModData()["uiBattery_powerLevel"]
end


function batteryManager.setPowerLevel(itemObj, powerLevel)
    itemObj:getModData()["uiBattery_powerLevel"] = powerLevel
end


function batteryManager.updateActiveState(itemObj, plObj)
    local isActive = itemObj:getModData()["uiBattery_active"] or false
    if isActive and not nvgCore.isValid(nil, plObj, itemObj) then
        batteryManager.deactivate(itemObj)
        isActive = false
    end
    return isActive
end


function batteryManager.activate(itemObj)
    if not itemObj:getModData()["uiBattery_active"] then
        itemObj:getModData()["uiBattery_active"] = true
        itemObj:getModData()["uiBattery_activeTime"] = getGameTime():getWorldAgeHours()
    end
end


function batteryManager.deactivate(itemObj)
    if itemObj:getModData()["uiBattery_active"] == true then
        itemObj:getModData()["uiBattery_active"] = false
    end
end


function batteryManager.addBattery(itemObj, plObj, batteryItem)
    itemObj:getModData()["uiBattery_battery"] = true
    itemObj:getModData()["uiBattery_batteryLevel"] = batteryItem:getCurrentUsesFloat()
    batteryManager.refreshWeight(itemObj, batteryItem:getWeight())
    plObj:getInventory():Remove(batteryItem)
    sendRemoveItemFromContainer(plObj:getInventory(), batteryItem)
end


function batteryManager.removeBattery(itemObj, plObj)
    local batteryObj = instanceItem(batteryManager.batteryItemType)
    batteryObj:setUsedDelta(itemObj:getModData()["uiBattery_batteryLevel"])
    plObj:getInventory():AddItem(batteryObj)
    sendAddItemToContainer(plObj:getInventory(), batteryObj)
    itemObj:getModData()["uiBattery_battery"] = false
    itemObj:getModData()["uiBattery_batteryLevel"] = 0
    batteryManager.refreshWeight(itemObj)
    batteryManager.deactivate(itemObj)
end


function batteryManager.initialise(itemObj)
    local initialiseItem = (not itemObj:getModData()["uiBattery_initialised"])
    if initialiseItem then
        local hadBattery = itemObj:getModData()["uiBattery_battery"]
        local hasBattery = (initialiseItem and ZombRandBetween(0, 10) < 5 and true) or hadBattery or false
        itemObj:getModData()["uiBattery_active"] = false
        itemObj:getModData()["uiBattery_battery"] = hasBattery
        itemObj:getModData()["uiBattery_batteryLevel"] = (hadBattery and 1) or (hasBattery and (ZombRandBetween(0, 10) / 10)) or 0
        itemObj:getModData()["uiBattery_powerLevel"] = 1
        itemObj:getModData()["uiBattery_initialised"] = true
    elseif batteryManager.hasBattery(itemObj) and type(itemObj:getModData()["uiBattery_batteryLevel"]) ~= "number" then
        itemObj:getModData()["uiBattery_batteryLevel"] = ZombRandBetween(0, 10) / 10
    end
    batteryManager.refreshWeight(itemObj)
end


function batteryManager.drainItem(itemObj)
    if not itemObj:getModData()["uiBattery_active"] then return end

    local batteryLevel = itemObj:getModData()["uiBattery_batteryLevel"] or 0
    if batteryLevel <= 0 then
        batteryManager.deactivate(itemObj)
        return
    end

    local powerLevel = itemObj:getModData()["uiBattery_powerLevel"] or 1
    local worldTime = getGameTime():getWorldAgeHours()
    local activeTime = itemObj:getModData()["uiBattery_activeTime"] or worldTime

    local drainMultiplier = compat.getDeviceSpec(itemObj:getFullType()).batteryDrainMultiplier or 1
    local lifeMultiplier = (SandboxVars.NightVisionChucked and SandboxVars.NightVisionChucked.BatteryLifeMultiplier) or 1
    if lifeMultiplier < 0.01 then lifeMultiplier = 0.01 end
    local effectiveRuntime = (batteryManager.runtime / drainMultiplier) * lifeMultiplier

    batteryLevel = batteryLevel - (powerLevel * ((worldTime - activeTime) / effectiveRuntime))
    if batteryLevel < 0 then batteryLevel = 0 end

    itemObj:getModData()["uiBattery_batteryLevel"] = batteryLevel
    itemObj:getModData()["uiBattery_activeTime"] = worldTime

    if batteryLevel == 0 then
        batteryManager.deactivate(itemObj)
    end
end


function batteryManager.drainWornNVG(character)
    local wornItems = character:getWornItems()
    for i = 1, wornItems:size() do
        local item = wornItems:getItemByIndex(i - 1)
        if item and appliedNVGChuckedTypes[item:getFullType()] then
            batteryManager.drainItem(item)
        end
    end

    local weapon = character:getPrimaryHandItem()
    if weapon and weapon:getCategory() == "Weapon" and weapon:isRanged() then
        local attachment = weapon:getActiveSight()
        if attachment and appliedNVGChuckedTypes[attachment:getFullType()] then
            batteryManager.drainItem(attachment)
        end
    end
end


function batteryManager.tick()
    if isClient() then return end
    local players = isServer() and getOnlinePlayers() or IsoPlayer.getPlayers()
    if not players then return end

    for i = 0, players:size() - 1 do
        local player = players:get(i)
        if player then
            batteryManager.drainWornNVG(player)
        end
    end
end



return batteryManager
