local nvgCore = {}

appliedNVGChuckedTypes = appliedNVGChuckedTypes or {}
appliedNVGActivatableTypes = appliedNVGActivatableTypes or {}

function applyNVGchucked_ModuleType(moduleDotTypeString)
    appliedNVGChuckedTypes = appliedNVGChuckedTypes or {}
    appliedNVGActivatableTypes = appliedNVGActivatableTypes or {}
    appliedNVGChuckedTypes[moduleDotTypeString] = true
    appliedNVGActivatableTypes[moduleDotTypeString] = true
    print("MOD: nightVisionChucked: applying to: "..moduleDotTypeString)
end


local nvgTypesPopulated = false

function nvgCore.getNVGTypes()
    if nvgTypesPopulated then return end

    local SM = getScriptManager()
    local allItems = SM:getAllItems()

    for i = 0, allItems:size() - 1 do
        local itemScript = allItems:get(i)
        local itemScriptModuleDotType = itemScript:getFullName()

        if itemScript:hasTag(NIGHTVISION_CHUCKED_TAGS.NVG) then
            appliedNVGChuckedTypes[itemScriptModuleDotType] = true
            appliedNVGActivatableTypes[itemScriptModuleDotType] = true
        elseif itemScript:hasTag(NIGHTVISION_CHUCKED_TAGS.BATTERY) then
            appliedNVGChuckedTypes[itemScriptModuleDotType] = true
        end
    end

    nvgTypesPopulated = true
end


function nvgCore.getItemID(itemObj)
    return itemObj:getType() .. itemObj:getID()
end


function nvgCore.isActive(_, plObj)
    local wornItems = plObj:getWornItems()
    for i = 1, wornItems:size() do
        local item = wornItems:getItemByIndex(i - 1)
        if item and appliedNVGChuckedTypes[item:getFullType()] and item:getModData()["uiBattery_active"] then
            return true
        end
    end

    local weapon = plObj:getPrimaryHandItem()
    if weapon and weapon:getCategory() == "Weapon" and weapon:isRanged() then
        local attachment = weapon:getActiveSight()
        if attachment and appliedNVGChuckedTypes[attachment:getFullType()] and attachment:getModData()["uiBattery_active"] then
            return true
        end
    end

    return false
end


function nvgCore.isWearing(_, plObj, itemObj)
    return plObj:isEquippedClothing(itemObj) or false
end


function nvgCore.findActivatableExtra(item)
    if not item:IsClothing() then return nil end
    local extraList = item:getClothingItemExtra()
    if not extraList then return nil end

    local itemModule = item:getModule()
    for i = 0, extraList:size() - 1 do
        local moduleDotType = itemModule .. "." .. extraList:get(i)
        if appliedNVGActivatableTypes[moduleDotType] then
            return moduleDotType
        end
    end
    return nil
end


function nvgCore.flipAndActivate(plObj, item)
    if isServer() then return false end
    local targetType = nvgCore.findActivatableExtra(item)
    if not targetType then return false end

    local action = ISClothingExtraAction:new(plObj, item, targetType)
    action.nvgAutoActivate = true
    ISTimedActionQueue.add(action)
    return true
end


function nvgCore.isWielding(_, plObj, itemObj)
    local weapon = plObj:getPrimaryHandItem()
    if not weapon or weapon:getCategory() ~= "Weapon" or not weapon:isRanged() then
        return false
    end
    return weapon:getActiveSight() == itemObj and plObj:isAiming() or false
end


function nvgCore.isInPlayerInventory(_, plObj, itemObj)
    return itemObj:getContainer() == plObj:getInventory() or false
end


function nvgCore.isValid(_, plObj, itemObj)
    if plObj and itemObj then
        return nvgCore.isWearing(_, plObj, itemObj) or nvgCore.isWielding(_, plObj, itemObj) or false
    end
    return nil
end


return nvgCore
