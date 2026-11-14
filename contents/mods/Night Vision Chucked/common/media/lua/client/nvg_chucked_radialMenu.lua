require "ISUI/ISLightSourceRadialMenu"
require "ISUI/ISInventoryPaneContextMenu"

local nvg = require "nvg_chucked_nvg.lua"
local nvgCore = require "nvg_chucked_core.lua"
local batteryManager = require "nvg_chucked_batteryManager.lua"

local radialMenu = {}

radialMenu.textures = {
    turnOn = getTexture("media/ui/vehicles/vehicle_lightsON.png"),
    turnOff = getTexture("media/ui/vehicles/vehicle_lightsOFF.png"),
    insertBattery = getTexture("media/ui/LightSourceRadial_InsertBattery.png"),
    removeBattery = getTexture("media/ui/LightSourceRadial_RemoveBattery.png"),
    back = getTexture("media/ui/emotes/back.png"),
}


function radialMenu.getPercentText(value)
    return math.floor((value or 0) * 100 + 0.5) .. "%"
end


function radialMenu.getBatteries(plObj)
    local batteries = {}
    local seenPercent = {}
    local items = plObj:getInventory():getItemsFromFullType("Base.Battery")
    for i = 1, items:size() do
        local battery = items:get(i - 1)
        local percentText = radialMenu.getPercentText(battery:getCurrentUsesFloat())
        if battery:getCurrentUsesFloat() > 0 and not seenPercent[percentText] then
            seenPercent[percentText] = true
            table.insert(batteries, battery)
        end
    end
    table.sort(batteries, function(a, b) return a:getCurrentUsesFloat() > b:getCurrentUsesFloat() end)
    return batteries
end


function radialMenu.getBatteryManager(plObj, itemObj)
    local itemID = nvgCore.getItemID(itemObj)
    if not nvg.batteryManagers[itemID] then nvg.initialiseNVG(itemID, plObj, itemObj) end
    return nvg.batteryManagers[itemID]
end


function radialMenu.fillMainMenu(lightRadial)
    lightRadial:fillMenu()
    lightRadial:display()
end


function radialMenu.fillBatteryMenu(lightRadial, itemObj, batteries)
    local menu = getPlayerRadialMenu(lightRadial.playerNum)
    menu:clear()

    local itemBatteryManager = radialMenu.getBatteryManager(lightRadial.character, itemObj)
    for _, battery in ipairs(batteries) do
        local text = battery:getDisplayName() .. "\n" .. radialMenu.getPercentText(battery:getCurrentUsesFloat())
        menu:addSlice(text, battery:getTex(), itemBatteryManager.doAction, itemBatteryManager, "AddBattery", battery)
    end

    menu:addSlice(getText("IGUI_Emote_Back"), radialMenu.textures.back, radialMenu.fillDeviceMenu, lightRadial, itemObj)
    lightRadial:display()
end


function radialMenu.fillDeviceMenu(lightRadial, itemObj)
    local plObj = lightRadial.character
    local menu = getPlayerRadialMenu(lightRadial.playerNum)
    menu:clear()

    local name = itemObj:getDisplayName()
    local itemBatteryManager = radialMenu.getBatteryManager(plObj, itemObj)

    menu:addSlice(name .. "\n" .. getText("IGUI_DeviceOptions"), itemObj:getTex(), nvg.openDeviceOptions, itemObj, plObj)

    if itemBatteryManager then

        if appliedNVGActivatableTypes[itemObj:getFullType()] then
            if batteryManager.updateActiveState(itemObj, plObj) then
                menu:addSlice(name .. "\n" .. getText("ContextMenu_Turn_Off"), radialMenu.textures.turnOff, itemBatteryManager.doAction, itemBatteryManager, "Deactivate")
            elseif (batteryManager.hasBattery(itemObj) and batteryManager.hasPower(itemObj)) or batteryManager.hasAlternatePower(itemObj) then
                menu:addSlice(name .. "\n" .. getText("ContextMenu_Turn_On"), radialMenu.textures.turnOn, itemBatteryManager.doAction, itemBatteryManager, "Activate")
            end
        elseif nvgCore.findActivatableExtra(itemObj) then
            menu:addSlice(name .. "\n" .. getText("ContextMenu_Turn_On"), radialMenu.textures.turnOn, nvgCore.flipAndActivate, plObj, itemObj)
        end

        if batteryManager.hasBattery(itemObj) then
            local text = getText("ContextMenu_Remove_Battery") .. "\n" .. radialMenu.getPercentText(itemObj:getModData()["uiBattery_batteryLevel"])
            menu:addSlice(text, radialMenu.textures.removeBattery, itemBatteryManager.doAction, itemBatteryManager, "RemoveBattery")
        else
            local batteries = radialMenu.getBatteries(plObj)
            if #batteries == 1 then
                local text = getText("ContextMenu_AddBattery") .. "\n" .. radialMenu.getPercentText(batteries[1]:getCurrentUsesFloat())
                menu:addSlice(text, radialMenu.textures.insertBattery, itemBatteryManager.doAction, itemBatteryManager, "AddBattery", batteries[1])
            elseif #batteries > 1 then
                menu:addSlice(getText("ContextMenu_AddBattery"), radialMenu.textures.insertBattery, radialMenu.fillBatteryMenu, lightRadial, itemObj, batteries)
            end
        end
    end

    local extraOptions = itemObj:getClothingItemExtraOption()
    local extraTypes = itemObj:getClothingItemExtra()
    if extraOptions and extraTypes then
        for i = 0, extraOptions:size() - 1 do
            local itemType = moduleDotType(itemObj:getModule(), extraTypes:get(i))
            local extraItem = ISInventoryPaneContextMenu.getItemInstance(itemType)
            local texture = extraItem and extraItem:getTex() or itemObj:getTex()
            menu:addSlice(getText("ContextMenu_" .. extraOptions:get(i)), texture, ISInventoryPaneContextMenu.onClothingItemExtra, itemObj, itemType, plObj)
        end
    end

    menu:addSlice(getText("IGUI_Emote_Back"), radialMenu.textures.back, radialMenu.fillMainMenu, lightRadial)
    lightRadial:display()
end


function radialMenu.addSlices(lightRadial)
    local plObj = lightRadial.character
    local menu = getPlayerRadialMenu(lightRadial.playerNum)
    local wornItems = plObj:getWornItems()
    for i = 1, wornItems:size() do
        local itemObj = wornItems:getItemByIndex(i - 1)
        if itemObj and appliedNVGChuckedTypes[itemObj:getFullType()] then
            menu:addSlice(itemObj:getDisplayName() .. "\n" .. getText("IGUI_DeviceOptions"), itemObj:getTex(), radialMenu.fillDeviceMenu, lightRadial, itemObj)
        end
    end
end


local ISLightSourceRadialMenu_fillMenu = ISLightSourceRadialMenu.fillMenu
function ISLightSourceRadialMenu:fillMenu()
    ISLightSourceRadialMenu_fillMenu(self)
    radialMenu.addSlices(self)
end


return radialMenu
