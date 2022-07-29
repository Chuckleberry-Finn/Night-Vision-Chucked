-- This line is required to ensure proper loading:
if getActivatedMods():contains("NightVisionChucked") then require("eris_nvg/eris_nvg/eris_nvg") else return end

--[[ singleMethod ]]
applyNVGchucked_ModuleType("Base.Animask23")
applyNVGchucked_ModuleType("Base.Mask_HECU")

--[[ batchMethod ]]
for _,type in pairs({
    "Base.Hat_PVS_5", "Base.Hat_PVS15", "Base.Hat_Sam_NV", "Base.Hat_PVS15_ON",
    "Base.Hat_PVS15_Harness_ON", "Base.Hat_NV18_ON", "Base.Hat_NV18_Harness_ON",
}) do applyNVGchucked_ModuleType(type) end

--[[ scriptMethod
module EXAMPLE_MODULE
{
    item EXAMPLE_TYPE
    {
        Type = Clothing, --REQUIRED--
        Tags = NVGchucked, --REQUIRED--

        -- Everything else can be what ever you want. --
    }
}
--]]

