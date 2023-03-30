require "TimedActions/ISUnequipAction"
-- eris_nvg - night vision goggles
-- item artwork: Lith
-- chucking: chuckleberry "chuck" finn

local eris_nvg = {
	batteryManagers = {},
	numActiveNVG = 0,
	activeNVG = {},
	playerScreenBounds = {},
	brightnessOverlay = getTexture("media/textures/overlayBrightness.png"),
}


function eris_nvg.doCheck(_plObj)
	for itemID, batteryManager in pairs(eris_nvg.batteryManagers) do
		batteryManager:update()
	end
end


appliedNVGChuckedTypes = appliedNVGChuckedTypes or {}
function applyNVGchucked_ModuleType(moduleDotTypeString)
	appliedNVGChuckedTypes = appliedNVGChuckedTypes or {}
	appliedNVGChuckedTypes[moduleDotTypeString] = true
	print("MOD: nightVisionChucked: applying to: "..moduleDotTypeString)
end

local function getNVGTypes()
	local SM = getScriptManager()
	local allItems = SM:getAllItems()

	for i=0, allItems:size()-1 do
		---@type Item
		local itemScript = allItems:get(i)
		local itemScriptModuleDotType = itemScript:getFullName()

		if itemScript then--and tostring(itemScript:getType()) == "Clothing" then

			if itemScript:getTags() and (itemScript:getTags():contains("NVGchucked") or itemScript:getTags():contains("NVITEM")) then
				appliedNVGChuckedTypes[itemScriptModuleDotType] = true
			end
		--else
		--	if appliedNVGChuckedTypes[itemScriptModuleDotType] == true then
		--		print("WARNING: nightVisionChucked: \""..itemScriptModuleDotType.."\" not clothing; removed from applied types.")
		--		appliedNVGChuckedTypes[itemScriptModuleDotType] = nil
		--	end
		end
	end
end
Events.OnGameStart.Add(getNVGTypes)


function eris_nvg.doMenu(_plID, _context, _items)
	local isWearing
	local itemObj
	local itemID
	local plObj = getPlayer(_plID)
	for i, items in ipairs(_items) do
		if not instanceof(items, "InventoryItem") then itemObj = items.items[1] else itemObj = items end
		if itemObj then
			if eris_nvg.isInPlayerInventory(nil, plObj, itemObj) and appliedNVGChuckedTypes[itemObj:getFullType()] then
				itemID = eris_nvg.getItemID(itemObj)
				if not eris_nvg.batteryManagers[itemID] then eris_nvg.initialiseNVG(itemID, plObj, itemObj) end
				isWearing = eris_nvg.isWearing(nil, plObj, itemObj)
				if isWearing then eris_nvg.batteryManagers[itemID]:doActionMenu(_context) end
				eris_nvg.batteryManagers[itemID]:doPowerLevelMenu(_context)
				eris_nvg.batteryManagers[itemID]:doBatteryMenu(_context)
			end
		end
	end
end


function eris_nvg.isActive(_, _plObj, _itemObj)
	return _plObj:isWearingNightVisionGoggles() or false
end


function eris_nvg.isWearing(_, _plObj, _itemObj)
	return _itemObj:getBodyLocation() or false
	--return _plObj:getClothingItem_Head() == _itemObj or false
end


function eris_nvg.isInPlayerInventory(_, _plObj, _itemObj)
	return _itemObj:getContainer() == _plObj:getInventory() or false
end


function eris_nvg.isValid(_, _plObj, _itemObj)
	if _plObj and _itemObj then
		return eris_nvg.isWearing(_, _plObj, _itemObj) or false
	else
		return nil
	end
	return false
end


function eris_nvg.onActivate(_, _plObj, _itemObj, _manager)
	if eris_nvg.activeNVG[_itemObj:getDisplayName() .. _plObj:getPlayerNum()] then return end
	eris_nvg.numActiveNVG = eris_nvg.numActiveNVG + 1
	_plObj:getEmitter():playSound("nvgTurnedOn")
	eris_nvg.updateScreenBounds()
	_plObj:setWearingNightVisionGoggles(true)
	eris_nvg.activeNVG[_itemObj:getDisplayName() .. _plObj:getPlayerNum()] = _manager
	Events.OnPreUIDraw.Add(eris_nvg.doBrightnessOverlay)
end


function eris_nvg.onBatteryDead(_, _plObj, _itemObj, _manager)
	eris_nvg.onDeactivate(_, _plObj, _itemObj, _manager)
	-- eris_nvg.batteryManagers[_itemObj:getType() .. _itemObj:getID()] = nil
end


function eris_nvg.onDeactivate(_, _plObj, _itemObj, _manager)
	if not eris_nvg.activeNVG[_itemObj:getDisplayName() .. _plObj:getPlayerNum()] then return end
	eris_nvg.numActiveNVG = eris_nvg.numActiveNVG-1
	eris_nvg.activeNVG[_itemObj:getDisplayName() .. _plObj:getPlayerNum()] = nil
	if eris_nvg.numActiveNVG < 0 then eris_nvg.numActiveNVG = 0 end
	if eris_nvg.numActiveNVG > 0 then return end
	_plObj:setWearingNightVisionGoggles(false)
	eris_nvg.updateScreenBounds()
	Events.OnPreUIDraw.Remove(eris_nvg.doBrightnessOverlay)
end


local ISUnequipAction_perform = ISUnequipAction.perform
function ISUnequipAction:perform()
	--self.item:
	if self.item and appliedNVGChuckedTypes[self.item:getFullType()] and eris_nvg.isActive(nil, self.character) then
		eris_nvg.onDeactivate(nil, self.character, self.item)
	end
	ISUnequipAction_perform(self)
end

local ISClothingExtraAction_perform = ISClothingExtraAction.perform
function ISClothingExtraAction:perform()
	ISClothingExtraAction_perform(self)
	if self.item and appliedNVGChuckedTypes[self.item:getFullType()] and eris_nvg.isActive(nil, self.character) then
		eris_nvg.onDeactivate(nil, self.character, self.item)
	end
end


function eris_nvg.onKeyPressed(key)
	local playerObj = getSpecificPlayer(0)
	if not playerObj then
		return
	end

	if key == getCore():getKey("Equip/Turn On/Off Light Source") then
		local wornItems = playerObj:getWornItems()

		for i=1,wornItems:size() do
			local item = wornItems:getItemByIndex(i-1)
			if item and appliedNVGChuckedTypes[item:getFullType()] and eris_nvg.isWearing(nil, playerObj, item) then

				local itemID = eris_nvg.getItemID(item)
				local itemBatteryManager = eris_nvg.batteryManagers[itemID]
				if not itemBatteryManager then
					eris_nvg.initialiseNVG(itemID, playerObj, item)
					itemBatteryManager = eris_nvg.batteryManagers[itemID]
				end

				if itemBatteryManager then
					if eris_nvg.isActive(nil, playerObj) then
						itemBatteryManager:doAction("Deactivate")
					elseif itemBatteryManager:hasBattery() and itemBatteryManager:hasPower() then
						itemBatteryManager:doAction("Activate")
					end
				end
			end
		end
	end
end
Events.OnKeyPressed.Add(eris_nvg.onKeyPressed)


---@param player IsoPlayer|IsoGameCharacter
function eris_nvg.aimingWithNVGScope(player)
	if not player then return end

	---@type HandWeapon|ISReloadableWeapon
	local weapon = player:getPrimaryHandItem()
	if weapon and weapon:getCategory() == "Weapon" and weapon:isRanged() then

		local attachment = weapon:getScope()
		if attachment and appliedNVGChuckedTypes[attachment:getFullType()] then

			local itemID = eris_nvg.getItemID(attachment)
			local itemBatteryManager = eris_nvg.batteryManagers[itemID]
			if not itemBatteryManager then
				eris_nvg.initialiseNVG(itemID, player, attachment)
				itemBatteryManager = eris_nvg.batteryManagers[itemID]
			end

			if itemBatteryManager and player:isAiming() then
				eris_nvg.onActivate(nil, player, attachment, itemBatteryManager)
			else
				eris_nvg.onDeactivate(nil, player, attachment, itemBatteryManager)
			end
		end
	end
end
Events.OnPlayerUpdate.Add(eris_nvg.aimingWithNVGScope)


function eris_nvg.initialiseNVG(_itemID, _plObj, _itemObj)
	local nvgObj = {
		plObj = _plObj,
		itemObj = _itemObj,
		runtime = 30,
		target = nil,
		adjustablePower = true,
		itemWeightNoBattery = 0.7,
		itemWeightWithBattery = 1.2,
		isValid = eris_nvg.isValid,
		isActive = eris_nvg.isActive,
		onActivate = eris_nvg.onActivate,
		onDeactivate = eris_nvg.onDeactivate,
		onBatteryDead = eris_nvg.onBatteryDead,
	}
	eris_nvg.batteryManagers[_itemID] = eris_uiBattery:new(nvgObj)
	eris_nvg.batteryManagers[_itemID]:initialise()
end


function eris_nvg.getItemID(_itemObj)
	return _itemObj:getType() .. _itemObj:getID()
end


function eris_nvg.initInvInfo()
	local nvBar
	for i, item in ipairs(appliedNVGChuckedTypes) do
		nvBar = {
			id = item,
			label = getTextOrNull("IGUI_invpanel_Remaining") or "Remaining: ",
			itemTest = function(_itemObj, _id) return _itemObj:getFullType() == _id end,
			getValue = function(_itemObj) return _itemObj:getModData()["uiBattery_batteryLevel"] end,
			setValue = function(_itemObj, _value) _itemObj:getModData()["uiBattery_batteryLevel"] = _value end,
		}
		-- eris_invBar.registerItem(nvBar.id, nvBar.label, nvBar.itemTest, nvBar.getValue, nvBar.setValue, true, true)
	end
end


function eris_nvg.init()
	eris_nvg.updateScreenBounds()
	Events.OnClothingUpdated.Add(eris_nvg.doCheck)
	Events.OnFillInventoryObjectContextMenu.Add(eris_nvg.doMenu)

	for type,_ in pairs(appliedNVGChuckedTypes) do
		eris_inventoryBar.registerItem(type, "uiBattery_batteryLevel", getTextOrNull("IGUI_invpanel_Remaining") or "Remaining: ")
		eris_inventoryTooltip.registerItem(type, "uiBattery_batteryLevel", getTextOrNull("IGUI_invpanel_Remaining") or "Remaining: ")
	end

	eris_nvg.initInvInfo()
end
Events.OnGameStart.Add(eris_nvg.init)


function eris_nvg.doBrightnessOverlay()
	local nvgItem
	local bounds, powerLevel
	for plID, manager in pairs(eris_nvg.activeNVG) do
		if manager then
			bounds = eris_nvg.playerScreenBounds[plID]
			powerLevel = manager:getPowerLevel()
			if bounds and powerLevel and eris_nvg.brightnessOverlay then
				UIManager.DrawTexture(eris_nvg.brightnessOverlay, bounds.x, bounds.y, bounds.w, bounds.h, 1 - powerLevel)
			end
		end
	end
end


function eris_nvg.updateScreenBounds()
	local plID
	local player, playerNum
	local x, y, w, h
	local playerList = IsoPlayer.getPlayers()
	if playerList then
		for i = 0, playerList:size() - 1 do
			player = playerList:get(i)
			if player then
				playerNum = player:getPlayerNum()
				plID = player:getDisplayName() .. playerNum
				eris_nvg.playerScreenBounds[plID] = {
					x = getPlayerScreenLeft(playerNum),
					y = getPlayerScreenTop(playerNum),
					w = getPlayerScreenWidth(playerNum),
					h = getPlayerScreenHeight(playerNum),
				}
				-- print("updating player " ..i)
				-- for k, v in pairs(eris_nvg.playerScreenBounds[plID]) do
					-- print(k, v)
				-- end
			end
		end
	end
end
Events.OnCreatePlayer.Add(eris_nvg.updateScreenBounds)
Events.OnResolutionChange.Add(eris_nvg.updateScreenBounds)