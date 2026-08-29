local nvgCore = {}

appliedNVGChuckedTypes = appliedNVGChuckedTypes or {}
function applyNVGchucked_ModuleType(moduleDotTypeString)
    appliedNVGChuckedTypes = appliedNVGChuckedTypes or {}
    appliedNVGChuckedTypes[moduleDotTypeString] = true
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
        end
    end

    nvgTypesPopulated = true
end


function nvgCore.getItemID(itemObj)
    return itemObj:getType() .. itemObj:getID()
end


function nvgCore.isActive(_, plObj)
    return plObj:isWearingNightVisionGoggles() or false
end


function nvgCore.isWearing(_, plObj, itemObj)
    return plObj:isEquippedClothing(itemObj) or false
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
