require "nvg_chucked_deviceWindow.lua"

local nvgCore = require "nvg_chucked_core.lua"
local batteryManager = require "nvg_chucked_batteryManager.lua"
local inventoryBar = require "nvg_chucked_inventoryBar.lua"
local inventoryTooltip = require "nvg_chucked_inventoryTooltip.lua"
local nvLight = require "nvg_chucked_light.lua"
local thermal = require "nvg_chucked_thermal.lua"
local compat = require "nvg_chucked_crossModCompat.lua"
local modOptions = require "nvg_chucked_modOptions.lua"

local nvg = {
    batteryManagers = {},
    numActiveNVG = 0,
    activeNVG = {},
    playerScreenBounds = {},
    greenOverlay = getTexture("media/textures/overlayGreen.png"),
}


function nvg.getActiveManager()
    for _, manager in pairs(nvg.activeNVG) do
        if manager then
            return manager
        end
    end
    return nil
end


function nvg.getActivePowerLevel()
    local manager = nvg.getActiveManager()
    return manager and (manager:getPowerLevel() or 1) or 1
end


function nvg.doCheck(_plObj)
    for itemID, batManager in pairs(nvg.batteryManagers) do
        batManager:reconcile()
    end

    if nvg.numActiveNVG > 0 then
        local manager = nvg.getActiveManager()
        local spec = manager and compat.getDeviceSpec(manager:getItem():getFullType()) or compat.deviceSpecDefault
        nvLight.update(_plObj, nvg.getActivePowerLevel(), spec.lightRadius, spec.lightBrightness)
        thermal.setEnabled(_plObj, spec.hasThermal)
        thermal.scan(_plObj)
    end
end


function nvg.doMenu(_plID, _context, _items)
    local isWearing
    local itemObj
    local itemID
    local plObj = getPlayer(_plID)
    for i, items in ipairs(_items) do
        if not instanceof(items, "InventoryItem") then itemObj = items.items[1] else itemObj = items end
        if itemObj then
            if nvgCore.isInPlayerInventory(nil, plObj, itemObj) and appliedNVGChuckedTypes[itemObj:getFullType()] then
                itemID = nvgCore.getItemID(itemObj)
                if not nvg.batteryManagers[itemID] then nvg.initialiseNVG(itemID, plObj, itemObj) end
                isWearing = nvgCore.isWearing(nil, plObj, itemObj)
                if isWearing then nvg.batteryManagers[itemID]:doActionMenu(_context) end
                _context:addOption(getText("IGUI_DeviceOptions"), itemObj, nvg.openDeviceOptions, plObj)
            end
        end
    end
end


function nvg.openDeviceOptions(itemObj, plObj)
    nightVisionChucked_deviceWindow.activate(plObj, itemObj)
end


function nvg.onActivate(_, _plObj, _itemObj, _manager)
    if nvg.activeNVG[_itemObj:getDisplayName() .. _plObj:getPlayerNum()] then return end
    nvg.numActiveNVG = nvg.numActiveNVG + 1
    _plObj:getEmitter():playSound("nvgTurnedOn")
    nvg.updateScreenBounds()
    nvg.activeNVG[_itemObj:getDisplayName() .. _plObj:getPlayerNum()] = _manager
    Events.OnPreUIDraw.Add(nvg.doGreenOverlay)
    local spec = compat.getDeviceSpec(_itemObj:getFullType())
    nvLight.update(_plObj, _manager:getPowerLevel(), spec.lightRadius, spec.lightBrightness)
    thermal.setEnabled(_plObj, spec.hasThermal)
end


function nvg.onBatteryDead(_, _plObj, _itemObj, _manager)
    nvg.onDeactivate(_, _plObj, _itemObj, _manager)
end


function nvg.onDeactivate(_, _plObj, _itemObj, _manager)
    if not nvg.activeNVG[_itemObj:getDisplayName() .. _plObj:getPlayerNum()] then return end
    nvg.numActiveNVG = nvg.numActiveNVG - 1
    nvg.activeNVG[_itemObj:getDisplayName() .. _plObj:getPlayerNum()] = nil
    if nvg.numActiveNVG < 0 then nvg.numActiveNVG = 0 end
    if nvg.numActiveNVG > 0 then return end
    nvg.updateScreenBounds()
    Events.OnPreUIDraw.Remove(nvg.doGreenOverlay)
    nvLight.remove()
    thermal.setEnabled(_plObj, false)
end


function nvg.onKeyStartPressed(key)
    if key ~= modOptions.getToggleKey() then return end
    nvg.toggleKeyPressedMs = getTimestampMs()
    nvg.toggleKeyRadialWasVisible = getPlayerRadialMenu(0):isReallyVisible()
end


function nvg.onKeyPressed(key)
    local playerObj = getSpecificPlayer(0)
    if not playerObj then
        return
    end

    if key == modOptions.getToggleKey() then

        if getCore():isKey(KeybindId.LIGHT_SOURCE, key) then
            local pressedMs = nvg.toggleKeyPressedMs
            nvg.toggleKeyPressedMs = nil
            if not pressedMs or nvg.toggleKeyRadialWasVisible or getTimestampMs() - pressedMs >= 500 then return end
        end

        local wornItems = playerObj:getWornItems()

        for i = 1, wornItems:size() do
            local item = wornItems:getItemByIndex(i - 1)
            if item and nvgCore.isWearing(nil, playerObj, item) then

                if appliedNVGActivatableTypes[item:getFullType()] then
                    local itemID = nvgCore.getItemID(item)
                    local itemBatteryManager = nvg.batteryManagers[itemID]
                    if not itemBatteryManager then
                        nvg.initialiseNVG(itemID, playerObj, item)
                        itemBatteryManager = nvg.batteryManagers[itemID]
                    end

                    if itemBatteryManager then
                        if nvgCore.isActive(nil, playerObj) then
                            itemBatteryManager:doAction("Deactivate")
                        elseif batteryManager.hasBattery(item) and batteryManager.hasPower(item) then
                            itemBatteryManager:doAction("Activate")
                        end
                    end

                elseif appliedNVGChuckedTypes[item:getFullType()] then
                    nvgCore.flipAndActivate(playerObj, item)
                end
            end
        end
    end
end


---@param player IsoPlayer|IsoGameCharacter
function nvg.aimingWithNVGScope(player)
    if not player then return end

    ---@type HandWeapon
    local weapon = player:getPrimaryHandItem()
    if weapon and weapon:getCategory() == "Weapon" and weapon:isRanged() then

        local attachment = weapon:getActiveSight()
        if attachment and appliedNVGActivatableTypes[attachment:getFullType()] then

            local itemID = nvgCore.getItemID(attachment)
            if not nvg.batteryManagers[itemID] then
                nvg.initialiseNVG(itemID, player, attachment)
            end

            if player:isAiming() then
                batteryManager.activate(attachment)
            else
                batteryManager.deactivate(attachment)
            end
        end
    end
end


function nvg.initialiseNVG(_itemID, _plObj, _itemObj)
    local nvgObj = {
        plObj = _plObj,
        itemObj = _itemObj,
        target = nil,
        adjustablePower = true,
        isValid = nvgCore.isValid,
        isActive = nvgCore.isActive,
        onActivate = nvg.onActivate,
        onDeactivate = nvg.onDeactivate,
        onBatteryDead = nvg.onBatteryDead,
    }
    nvg.batteryManagers[_itemID] = nightVisionChucked_uiBattery:new(nvgObj)
    nvg.batteryManagers[_itemID]:initialise()
end


function nvg.initInvInfo()
    local nvBar
    for i, item in ipairs(appliedNVGChuckedTypes) do
        nvBar = {
            id = item,
            label = getTextOrNull("IGUI_invpanel_Remaining") or "Remaining: ",
            itemTest = function(_itemObj, _id) return _itemObj:getFullType() == _id end,
            getValue = function(_itemObj) return _itemObj:getModData()["uiBattery_batteryLevel"] end,
            setValue = function(_itemObj, _value) _itemObj:getModData()["uiBattery_batteryLevel"] = _value end,
        }
        -- inventoryBar.registerItem(nvBar.id, nvBar.label, nvBar.itemTest, nvBar.getValue, nvBar.setValue, true, true)
    end
end


function nvg.init()
    nvg.updateScreenBounds()
    Events.OnPlayerUpdate.Add(nvg.doCheck)
    Events.OnFillInventoryObjectContextMenu.Add(nvg.doMenu)

    for type, _ in pairs(appliedNVGChuckedTypes) do
        inventoryBar.registerItem(type, "uiBattery_batteryLevel", getTextOrNull("IGUI_invpanel_Remaining") or "Remaining: ")
        inventoryTooltip.registerItem(type, "uiBattery_batteryLevel", getTextOrNull("IGUI_invpanel_Remaining") or "Remaining: ")
    end

    nvg.initInvInfo()
end


nvg.greenTintAlphaMin = 0.30
nvg.greenTintAlphaMax = 0.45

function nvg.doGreenOverlay()
    local bounds, powerLevel
    for _, manager in pairs(nvg.activeNVG) do
        if manager then
            local plID = manager:getPlayer():getPlayerNum()
            bounds = nvg.playerScreenBounds[plID]
            powerLevel = manager:getPowerLevel()
            if bounds and powerLevel then
                if nvg.greenOverlay then
                    local tintAlpha = nvg.greenTintAlphaMin + (nvg.greenTintAlphaMax - nvg.greenTintAlphaMin) * powerLevel
                    UIManager.DrawTexture(nvg.greenOverlay, bounds.x, bounds.y, bounds.w, bounds.h, tintAlpha)
                end
            end
        end
    end
end


function nvg.updateScreenBounds()
    local plID
    local player, playerNum
    local playerList = IsoPlayer.getPlayers()
    if playerList then
        for i = 0, playerList:size() - 1 do
            player = playerList:get(i)
            if player then
                playerNum = player:getPlayerNum()
                plID = playerNum
                nvg.playerScreenBounds[plID] = {
                    x = getPlayerScreenLeft(playerNum),
                    y = getPlayerScreenTop(playerNum),
                    w = getPlayerScreenWidth(playerNum),
                    h = getPlayerScreenHeight(playerNum),
                }
            end
        end
    end
end

function nvg.resumeActiveNVG(plObj)
    if not plObj then return end

    nvgCore.getNVGTypes()

    local wornItems = plObj:getWornItems()
    for i = 1, wornItems:size() do
        local item = wornItems:getItemByIndex(i - 1)
        if item and appliedNVGChuckedTypes[item:getFullType()] then
            local itemID = nvgCore.getItemID(item)
            if not nvg.batteryManagers[itemID] then nvg.initialiseNVG(itemID, plObj, item) end
        end
    end

    local weapon = plObj:getPrimaryHandItem()
    if weapon and weapon:getCategory() == "Weapon" and weapon:isRanged() then
        local attachment = weapon:getActiveSight()
        if attachment and appliedNVGChuckedTypes[attachment:getFullType()] then
            local itemID = nvgCore.getItemID(attachment)
            if not nvg.batteryManagers[itemID] then nvg.initialiseNVG(itemID, plObj, attachment) end
        end
    end
end


function nvg.onCreatePlayer(_playerIndex)
    nvg.resumeActiveNVG(getSpecificPlayer(_playerIndex))
end


return nvg

