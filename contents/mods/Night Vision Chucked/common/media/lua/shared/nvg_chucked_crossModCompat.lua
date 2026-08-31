---{ SCRIPT METHOD } Adds the functionality through script using `Tags`.
--[[
module EXAMPLE_MODULE
{
    item EXAMPLE_TYPE
    {
        Tags = NVGchucked:NVG;NVGchucked:BATTERY,
    }
}
--]]

local compat = {}


compat.deviceSpecDefault = {
    lightRadius = 10,
    lightBrightness = 1.0,
    batteryDrainMultiplier = 1.0,
    hasThermal = false,
}


compat.pnvModels = {

    {
        down = "NVG_PNV-10T_DOWN",
        up = "NVG_PNV-10T_UP",
        hasHeadStrap = true,
        spec = {
            lightRadius = 6,
            lightBrightness = 0.7,
            batteryDrainMultiplier = 1.4,
            hasThermal = false,
        },
    },

    {
        down = "NVG_ANPVS-14_DOWN",
        up = "NVG_ANPVS-14_UP",
        hasHeadStrap = true,
        spec = {
            lightRadius = 10,
            lightBrightness = 1.0,
            batteryDrainMultiplier = 1.0,
            hasThermal = false,
        },
    },

    {
        down = "NVG_ArmasightN-15_DOWN",
        up = "NVG_ArmasightN-15_UP",
        hasHeadStrap = true,
        spec = {
            lightRadius = 13,
            lightBrightness = 1.15,
            batteryDrainMultiplier = 0.9,
            hasThermal = false,
        },
    },

    {
        down = "NVG_GPNVG-18_DOWN",
        up = "NVG_GPNVG-18_UP",
        hasHeadStrap = true,
        spec = {
            lightRadius = 16,
            lightBrightness = 1.25,
            batteryDrainMultiplier = 0.7,
            hasThermal = true,
        },
    },
}


compat.deviceSpecs = {}
for _, model in ipairs(compat.pnvModels) do
    compat.deviceSpecs[model.down] = model.spec
    if model.hasHeadStrap then
        compat.deviceSpecs[model.down .. "-HeadStrap"] = model.spec
    end
end


function compat.getDeviceSpec(itemType)
    if not itemType then return compat.deviceSpecDefault end
    local shortType = itemType:match("%.([^.]+)$") or itemType
    return compat.deviceSpecs[shortType] or compat.deviceSpecDefault
end


function compat.PNV()
    local scriptManager = getScriptManager()

    --- Mods using 'NVITEM' for item tags are not using the new tag method, trying to fetch matches will return incorrect items
    --local pnvItems = scriptManager:getItemsTag(ItemTag.NVITEM)

    local function applyTags(_type, _tags)
        if not _type then return end
        ---@type Item
        local nvItem = scriptManager:getItem(_type)
        if nvItem then
            print("APPLYING NVG TAGS TO NVITEM ITEM: ", nvItem:getFullName())
            local itemTags = nvItem:getTags()
            for j = 1, #_tags do
                if not itemTags:contains(_tags[j]) then itemTags:add(_tags[j]) end
            end
        end
    end

    for _, model in ipairs(compat.pnvModels) do
        applyTags(model.down, {NIGHTVISION_CHUCKED_TAGS.NVG, NIGHTVISION_CHUCKED_TAGS.BATTERY})
        applyTags(model.up, {NIGHTVISION_CHUCKED_TAGS.BATTERY})

        if model.hasHeadStrap then
            applyTags(model.down .. "-HeadStrap", {NIGHTVISION_CHUCKED_TAGS.NVG, NIGHTVISION_CHUCKED_TAGS.BATTERY})
            applyTags(model.up .. "-HeadStrap", {NIGHTVISION_CHUCKED_TAGS.BATTERY})
        end
    end
end

return compat
