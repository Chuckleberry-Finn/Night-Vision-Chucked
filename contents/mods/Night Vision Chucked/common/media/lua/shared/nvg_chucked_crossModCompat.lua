---{ SCRIPT METHOD } Adds the functionality through script using `Tags`.
--[[
module EXAMPLE_MODULE
{
    item EXAMPLE_TYPE
    {
        Tags = NVGchucked:NVG,
    }
}
--]]

local compat = {}
function compat.PNV()
    local scriptManager = getScriptManager()

    --- Mods using 'NVITEM' for item tags are not using the new tag method, trying to fetch matches will return incorrect items
    --local pnvItems = scriptManager:getItemsTag(ItemTag.NVITEM)

    local pnvGoggles = {"NVG_ANPVS-14_DOWN",
                        "NVG_ANPVS-14_DOWN-HeadStrap",
                        "NVG_ArmasightN-15_DOWN",
                        "NVG_ArmasightN-15_DOWN-HeadStrap",
                        "NVG_GPNVG-18_DOWN",
                        "NVG_GPNVG-18_DOWN-HeadStrap",
                        "NVG_PNV-10T_DOWN",
                        "NVG_PNV-10T_DOWN-HeadStrap",
    }

    for i=1, #pnvGoggles do
        ---@type Item
        local nvType = pnvGoggles[i]
        local nvItem = scriptManager:getItem(nvType)
        if nvItem then
            print("APPLYING NVG TAG TO NVITEM ITEM: ", nvItem:getFullName())
            local tags = nvItem:getTags()
            if not tags:contains(NIGHTVISION_CHUCKED_TAGS.NVG) then tags:add(NIGHTVISION_CHUCKED_TAGS.NVG) end
        end
    end
end

return compat