local batteryManager = require "nvg_chucked_batteryManager.lua"

nightVisionChucked_uiBattery = ISUIElement:derive("nightVisionChucked_uiBattery")


function nightVisionChucked_uiBattery:activate()
    if not self.active then
        self.active = true
        self.onActivate(self.target, self.plObj, self.itemObj, self)
        self:addToUIManager()
    end
end


function nightVisionChucked_uiBattery:deactivate(_batteryDead)
    if self.active then
        self.active = false
        if _batteryDead then
            self.onBatteryDead(self.target, self.plObj, self.itemObj, self)
        else
            self.onDeactivate(self.target, self.plObj, self.itemObj, self)
        end
        self:removeFromUIManager()
    end
end


function nightVisionChucked_uiBattery:doAction(_doAction, _itemObj2, _powerLevel)
    local action = nightVisionChucked_uiBatteryAction:new(self.plObj, self.itemObj, _doAction, _itemObj2, _powerLevel)
    ISTimedActionQueue.add(action)
end


function nightVisionChucked_uiBattery:doActionMenu(_context)
    local isActive = batteryManager.updateActiveState(self.itemObj, self.plObj)
    if not isActive and appliedNVGActivatableTypes[self.itemObj:getFullType()] and batteryManager.hasBattery(self.itemObj) and batteryManager.hasPower(self.itemObj) and self.plObj:isEquippedClothing(self.itemObj) then
        _context:addOption(getTextOrNull("ContextMenu_Turn_On") or "Activate", self, nightVisionChucked_uiBattery.doAction, "Activate")
    elseif isActive then
        _context:addOption(getTextOrNull("ContextMenu_Turn_Off") or "Deactivate", self, nightVisionChucked_uiBattery.doAction, "Deactivate")
    end
end


function nightVisionChucked_uiBattery:getPlayer()
    return self.plObj
end


function nightVisionChucked_uiBattery:getItem()
    return self.itemObj
end


function nightVisionChucked_uiBattery:getPowerLevel()
    return batteryManager.getPowerLevel(self.itemObj)
end


--TODO: HUD battery meter
function nightVisionChucked_uiBattery:prerender() end
function nightVisionChucked_uiBattery:render() end


function nightVisionChucked_uiBattery:reconcile()
    local isValid = self.isValid(self.target, self.plObj, self.itemObj)
    if not isValid then
        self:deactivate()
        return
    end

    local wasActive = self.active
    local nowActive = batteryManager.updateActiveState(self.itemObj, self.plObj)

    if nowActive and not wasActive then
        self:activate()
    elseif wasActive and not nowActive then
        local batteryDead = (self.itemObj:getModData()["uiBattery_batteryLevel"] or 0) <= 0
        self:deactivate(batteryDead)
    end
end


function nightVisionChucked_uiBattery:update()
    self:reconcile()
end


function nightVisionChucked_uiBattery:initialise()
    ISUIElement.initialise(self)
    batteryManager.initialise(self.itemObj)
    if self.itemObj:getModData()["uiBattery_active"] then
        self:activate()
    end
end


function nightVisionChucked_uiBattery:new(_obj)
    local o = ISUIElement:new(0, 0, 0, 0)
    setmetatable(o, self)
    self.__index = self
    for k, v in pairs(_obj) do o[k] = v end
    o.target = o.target or {}
    o.active = false
    return o
end
