local modOptions = {}

modOptions.defaultToggleKey = Keyboard.KEY_F

modOptions.toggleKeyOption = nil

local function createModOptionsUI()
    if not PZAPI or not PZAPI.ModOptions then return end

    local options = PZAPI.ModOptions:create("NightVisionChucked", getTextOrNull("UI_ConfigMODID_NightVisionChucked") or "Night Vision Chucked")

    modOptions.toggleKeyOption = options:addKeyBind(
        "nvg_ToggleKey",
        getTextOrNull("UI_NVG_ToggleKey") or "NVG Toggle Key",
        modOptions.defaultToggleKey,
        getTextOrNull("UI_NVG_ToggleKeyToolTip") or "Key used to turn NVG on/off and flip the visor."
    )

    PZAPI.ModOptions:load()
end


function modOptions.getToggleKey()
    if modOptions.toggleKeyOption then
        return modOptions.toggleKeyOption:getValue()
    end
    return modOptions.defaultToggleKey
end


Events.OnGameBoot.Add(createModOptionsUI)

return modOptions
