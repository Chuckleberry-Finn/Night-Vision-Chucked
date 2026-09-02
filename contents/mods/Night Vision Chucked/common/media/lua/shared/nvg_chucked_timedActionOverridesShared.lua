require "TimedActions/ISClothingExtraAction"
local batteryManager = require "nvg_chucked_batteryManager.lua"
local nvg = require "nvg_chucked_nvg.lua"
local nvgCore = require "nvg_chucked_core.lua"

local function deactivatedAndSetPendingReactivate(item, character)
    if item and appliedNVGActivatableTypes[item:getFullType()] and nvgCore.isActive(nil, character) then
        item:getModData()["uiBattery_reactivatePending"] = true
        batteryManager.deactivate(item)
        if not isServer() then nvg.onDeactivate(nil, character, item) end
    end
end


---UNEQUIP
local ISUnequipAction_perform = ISUnequipAction.perform
function ISUnequipAction:perform()
    deactivatedAndSetPendingReactivate(self.item, self.character)
    ISUnequipAction_perform(self)
end


---WEAR
local ISWearClothing_complete = ISWearClothing.complete
function ISWearClothing:complete()
    local autoActivate = self.nvgAutoActivate
    local item = self.item
    local result = ISWearClothing_complete(self)

    if autoActivate and result ~= false and item and appliedNVGChuckedTypes[item:getFullType()] then
        if appliedNVGActivatableTypes[item:getFullType()] then

            if not isServer() then
                local itemID = nvgCore.getItemID(item)
                if not nvg.batteryManagers[itemID] then nvg.initialiseNVG(itemID, self.character, item) end
                local itemBatteryManager = nvg.batteryManagers[itemID]
                if itemBatteryManager and batteryManager.hasBattery(item) and batteryManager.hasPower(item) then
                    itemBatteryManager:doAction("Activate")
                end
            end

        else
            nvgCore.flipAndActivate(self.character, item)
        end
    end

    return result
end


---EXTRA_ACTION
local ISClothingExtraAction_createItemNew = ISClothingExtraAction.createItemNew
function ISClothingExtraAction:createItemNew(item, newItem)
    local itemNew = ISClothingExtraAction_createItemNew(self, item, newItem)
    self.nvc_newItem = itemNew
    if not isServer() then nvg.openDeviceOptions(newItem, self.character) end
    return itemNew
end


local ISClothingExtraAction_perform = ISClothingExtraAction.perform
function ISClothingExtraAction:perform()
    ISClothingExtraAction_perform(self)
    deactivatedAndSetPendingReactivate(self.item, self.character)
    if self.item and appliedNVGChuckedTypes[self.item:getFullType()] then
        local window = nightVisionChucked_deviceWindow.instances[self.character:getPlayerNum()]
        if window and window.itemObj == self.item then
            window.swapInProgress = true
        end
    end
end


local ISClothingExtraAction_stop = ISClothingExtraAction.stop
function ISClothingExtraAction:stop()
    local window = nightVisionChucked_deviceWindow.instances[self.character:getPlayerNum()]
    if window then window.swapInProgress = false end
    ISClothingExtraAction_stop(self)
end


local ISClothingExtraAction_complete = ISClothingExtraAction.complete
function ISClothingExtraAction:complete()
    local autoActivate = self.nvgAutoActivate

    ISClothingExtraAction_complete(self)

    local newItem = self.nvc_newItem
    if not newItem then return end

    local shouldActivate = autoActivate or newItem:getModData()["uiBattery_reactivatePending"]
    newItem:getModData()["uiBattery_reactivatePending"] = false

    if shouldActivate and appliedNVGActivatableTypes[newItem:getFullType()] then
        local itemID = nvgCore.getItemID(newItem)
        if not isServer() then

            nvg.openDeviceOptions(newItem, self.character)

            if not nvg.batteryManagers[itemID] then
                nvg.initialiseNVG(itemID, self.character, newItem)
            end
            local itemBatteryManager = nvg.batteryManagers[itemID]
            if itemBatteryManager and batteryManager.hasBattery(newItem) and batteryManager.hasPower(newItem) then
                itemBatteryManager:doAction("Activate")
            end
        end
    end
end