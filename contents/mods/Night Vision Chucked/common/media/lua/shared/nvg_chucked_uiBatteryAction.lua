require "TimedActions/ISBaseTimedAction"

local nvgCore = require "nvg_chucked_core.lua"
local batteryManager = require "nvg_chucked_batteryManager.lua"

nightVisionChucked_uiBatteryAction = ISBaseTimedAction:derive("nightVisionChucked_uiBatteryAction")


function nightVisionChucked_uiBatteryAction:isValid()
    if self.doAction then
        return self["isValid"..self.doAction](self)
    end
    return false
end


function nightVisionChucked_uiBatteryAction:perform()
    if self.doAction then
        self["perform"..self.doAction](self)
    end
    ISBaseTimedAction.perform(self)
end


function nightVisionChucked_uiBatteryAction:isValidActivate()
    return nvgCore.isValid(nil, self.character, self.itemObj)
        and not batteryManager.updateActiveState(self.itemObj, self.character)
        and (batteryManager.hasBattery(self.itemObj) and batteryManager.hasPower(self.itemObj)
            or batteryManager.hasAlternatePower(self.itemObj))
end


function nightVisionChucked_uiBatteryAction:performActivate()
    if self:isValidActivate() then
        batteryManager.activate(self.itemObj)
    end
end


function nightVisionChucked_uiBatteryAction:isValidAddBattery()
    return self.itemObj2 and not batteryManager.hasBattery(self.itemObj) or false
end


function nightVisionChucked_uiBatteryAction:performAddBattery()
    if self:isValidAddBattery() then
        batteryManager.addBattery(self.itemObj, self.character, self.itemObj2)
    end
end


function nightVisionChucked_uiBatteryAction:isValidDeactivate()
    return batteryManager.updateActiveState(self.itemObj, self.character) or false
end


function nightVisionChucked_uiBatteryAction:performDeactivate()
    if self:isValidDeactivate() then
        batteryManager.deactivate(self.itemObj)
    end
end


function nightVisionChucked_uiBatteryAction:isValidRemoveBattery()
    return batteryManager.hasBattery(self.itemObj)
end


function nightVisionChucked_uiBatteryAction:performRemoveBattery()
    if self:isValidRemoveBattery() then
        batteryManager.removeBattery(self.itemObj, self.character)
    end
end


function nightVisionChucked_uiBatteryAction:isValidSetPowerLevel()
    return self.powerLevel ~= nil
end


function nightVisionChucked_uiBatteryAction:performSetPowerLevel()
    if self.powerLevel then
        batteryManager.setPowerLevel(self.itemObj, self.powerLevel)
    end
end


function nightVisionChucked_uiBatteryAction:update()
end


function nightVisionChucked_uiBatteryAction:new(_plObj, _itemObj, _doAction, _itemObj2, _powerLevel)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = _plObj
    o.itemObj = _itemObj
    o.doAction = _doAction
    o.itemObj2 = _itemObj2
    o.powerLevel = _powerLevel
    o.stopOnWalk = false
    o.stopOnRun = true
    o.maxTime = 30
    return o
end
