require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"
require "ISUI/ISLabel"
require "RadioCom/ISUIRadio/ISLedLight"
require "RadioCom/ISUIRadio/ISItemDropBox"
require "RadioCom/ISUIRadio/ISBatteryStatusDisplay"
require "RadioCom/ISUIRadio/ISSliderPanel"

local nvgCore = require "nvg_chucked_core.lua"
local batteryManager = require "nvg_chucked_batteryManager.lua"

nightVisionChucked_deviceWindow = ISCollapsableWindow:derive("nightVisionChucked_deviceWindow")
nightVisionChucked_deviceWindow.instances = {}

local UI_BORDER_SPACING = 10
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local ROW_HGT = FONT_HGT_SMALL + 6


function nightVisionChucked_deviceWindow.activate(player, itemObj)
    local playerNum = player:getPlayerNum()
    local window = nightVisionChucked_deviceWindow.instances[playerNum]
    if not window then
        window = nightVisionChucked_deviceWindow:new(100, 100, 280, 160, player)
        window:initialise()
        window:instantiate()
        nightVisionChucked_deviceWindow.instances[playerNum] = window
    end

    window:setItem(itemObj)
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
end


function nightVisionChucked_deviceWindow:setItem(itemObj)
    self.itemObj = itemObj
    batteryManager.initialise(itemObj)
    self:setTitle(itemObj:getDisplayName())
end


function nightVisionChucked_deviceWindow:doAction(_doAction, _itemObj2, _powerLevel)
    local action = nightVisionChucked_uiBatteryAction:new(self.player, self.itemObj, _doAction, _itemObj2, _powerLevel)
    ISTimedActionQueue.add(action)
end


function nightVisionChucked_deviceWindow:initialise()
    ISCollapsableWindow.initialise(self)
end


function nightVisionChucked_deviceWindow:createChildren()
    ISCollapsableWindow.createChildren(self)

    local y = self:titleBarHeight() + UI_BORDER_SPACING

    self.led = ISLedLight:new(UI_BORDER_SPACING, y, UI_BORDER_SPACING * 2, UI_BORDER_SPACING * 2)
    self.led:initialise()
    self.led:setLedColor(1, 0, 1, 0)
    self.led:setLedColorOff(1, 0, 0.3, 0)
    self:addChild(self.led)

    local toggleX = self.led:getX() + self.led:getWidth() + UI_BORDER_SPACING
    local toggleW = UI_BORDER_SPACING * 2 + math.max(
        getTextManager():MeasureStringX(UIFont.Small, getText("ContextMenu_Turn_Off")),
        getTextManager():MeasureStringX(UIFont.Small, getText("ContextMenu_Turn_On"))
    )

    self.toggleButton = ISButton:new(toggleX, y - 1, toggleW, ROW_HGT, getText("ContextMenu_Turn_On"), self, nightVisionChucked_deviceWindow.onToggle)
    self.toggleButton:initialise()
    self.toggleButton.backgroundColor = { r = 0, g = 0, b = 0, a = 0.0 }
    self.toggleButton.backgroundColorMouseOver = { r = 1.0, g = 1.0, b = 1.0, a = 0.1 }
    self.toggleButton.borderColor = { r = 1.0, g = 1.0, b = 1.0, a = 0.3 }
    self:addChild(self.toggleButton)

    y = y + ROW_HGT + UI_BORDER_SPACING * 2

    self.batteryBox = ISItemDropBox:new(UI_BORDER_SPACING, y - 1, ROW_HGT, ROW_HGT, false, self, nightVisionChucked_deviceWindow.onBatteryDropped, nightVisionChucked_deviceWindow.onBatteryRemoved, nightVisionChucked_deviceWindow.verifyBattery, nil)
    self.batteryBox:initialise()
    self.batteryBox:setBackDropTex(getTexture("Item_Battery"), 0.4, 1, 1, 1)
    self.batteryBox:setDoBackDropTex(true)
    self.batteryBox:setToolTip(true, getText("IGUI_RadioDragBattery"))
    self:addChild(self.batteryBox)

    local statusX = self.batteryBox:getX() + self.batteryBox:getWidth() + UI_BORDER_SPACING
    self.batteryStatus = ISBatteryStatusDisplay:new(statusX, y - 1, self.width - statusX - UI_BORDER_SPACING, ROW_HGT, false)
    self.batteryStatus:initialise()
    function self.batteryStatus:update()
        ISPanel.update(self)
    end
    self:addChild(self.batteryStatus)

    y = y + ROW_HGT + UI_BORDER_SPACING * 2

    self.powerLabel = ISLabel:new(UI_BORDER_SPACING, y, FONT_HGT_SMALL, getText("IGUI_RadioPower"), 1, 1, 1, 1, UIFont.Small, true)
    self.powerLabel:initialise()
    self:addChild(self.powerLabel)

    y = y + FONT_HGT_SMALL + 4

    self.powerValueLabel = ISLabel:new(self.width - UI_BORDER_SPACING, y, ROW_HGT, "100%", 1, 1, 1, 1, UIFont.Small, false)
    self.powerValueLabel:initialise()
    self:addChild(self.powerValueLabel)

    self.powerSlider = ISSliderPanel:new(UI_BORDER_SPACING, y, self.powerValueLabel:getX() - UI_BORDER_SPACING * 2, ROW_HGT, self, nightVisionChucked_deviceWindow.onPowerLevelChange)
    self.powerSlider:initialise()
    self.powerSlider:setValues(10, 100, 10, 10, true)
    self:addChild(self.powerSlider)
end


function nightVisionChucked_deviceWindow:onToggle()
    if not self.itemObj then
        return
    end

    if not appliedNVGActivatableTypes[self.itemObj:getFullType()] then
        nvgCore.flipAndActivate(self.player, self.itemObj)
        return
    end

    local isActive = batteryManager.updateActiveState(self.itemObj, self.player)
    self:doAction(isActive and "Deactivate" or "Activate")
end


function nightVisionChucked_deviceWindow:verifyBattery(_item)
    return _item:getFullType() == "Base.Battery"
end


function nightVisionChucked_deviceWindow:onBatteryDropped(_items)
    if not self.itemObj then return end
    local item
    local best = -1
    for _, i in ipairs(_items) do
        if i:getCurrentUsesFloat() > best then
            item = i
            best = i:getCurrentUsesFloat()
        end
    end
    if item then
        self:doAction("AddBattery", item)
    end
end


function nightVisionChucked_deviceWindow:onBatteryRemoved()
    if not self.itemObj then return end
    self:doAction("RemoveBattery")
end


function nightVisionChucked_deviceWindow:onPowerLevelChange(_newValue)
    if not self.itemObj then return end
    batteryManager.setPowerLevel(self.itemObj, _newValue / 100)
    self.pendingPowerLevelCommitMs = getTimestampMs() + 200
end


function nightVisionChucked_deviceWindow:updateActive()
    local isActive = batteryManager.updateActiveState(self.itemObj, self.player)
    self.led:setLedIsOn(isActive)
    self.toggleButton:setTitle(isActive and getText("ContextMenu_Turn_Off") or getText("ContextMenu_Turn_On"))
end


function nightVisionChucked_deviceWindow:update()
    ISCollapsableWindow.update(self)

    if not self.itemObj then return end

    if not self.swapInProgress then
        local stillAccessible = nvgCore.isValid(nil, self.player, self.itemObj) or nvgCore.isInPlayerInventory(nil, self.player, self.itemObj)
        if not stillAccessible then
            self:close()
            return
        end
    end

    self:updateActive()

    if batteryManager.hasBattery(self.itemObj) then
        self.batteryBox:setStoredItemFake(self.batteryTex)
    else
        self.batteryBox:setStoredItemFake(nil)
    end

    local batteryLevel = tonumber(self.itemObj:getModData()["uiBattery_batteryLevel"]) or 0
    self.batteryStatus:setPower(batteryLevel)

    if self.pendingPowerLevelCommitMs and getTimestampMs() >= self.pendingPowerLevelCommitMs then
        self.pendingPowerLevelCommitMs = nil
        self:doAction("SetPowerLevel", nil, self.powerSlider:getCurrentValue() / 100)
    end

    if not self.powerSlider.dragInside and not self.pendingPowerLevelCommitMs then
        local powerLevel = batteryManager.getPowerLevel(self.itemObj) or 1
        self.powerSlider:setCurrentValue(powerLevel * 100, true)
    end
    self.powerValueLabel:setName(math.floor(self.powerSlider:getCurrentValue()) .. "%")
end


function nightVisionChucked_deviceWindow:new(x, y, width, height, player)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.player = player
    o.playerNum = player:getPlayerNum()
    o.batteryTex = getTexture("Item_Battery")
    o.resizable = false
    o.swapInProgress = false
    nightVisionChucked_deviceWindow.instance = o
    return o
end
