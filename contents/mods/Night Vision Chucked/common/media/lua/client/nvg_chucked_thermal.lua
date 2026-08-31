local thermal = {}

thermal.enabled = false
thermal.scanIntervalMs = 200
thermal.scanRadius = 30
thermal.outlineR = 1.0
thermal.outlineG = 0.0
thermal.outlineB = 0.6
thermal.outlineA = 1.0

local lastScanMs = 0
local tracked = {}


local function applyOutline(character, playerIndex)
    local key = tostring(character)
    if not tracked[key] then
        tracked[key] = {
            character = character,
            wasAttached = character:isOutlineHlAttached(playerIndex),
            wasBlinking = character:isOutlineHlBlink(playerIndex),
            owned = not character:isOutlineHighlight(playerIndex),
        }
    end

    local record = tracked[key]
    if not record.owned then return end

    character:setOutlineHighlightCol(playerIndex, thermal.outlineR, thermal.outlineG, thermal.outlineB, thermal.outlineA)
    character:setOutlineHlBlink(playerIndex, false)
    character:setOutlineHlAttached(playerIndex, true)
    character:setOutlineHighlight(playerIndex, true)
end


local function clearOutline(key, playerIndex)
    local record = tracked[key]
    if not record then return end

    if record.owned then
        record.character:setOutlineHighlight(playerIndex, false)
        record.character:setOutlineHlAttached(playerIndex, record.wasAttached)
        record.character:setOutlineHlBlink(playerIndex, record.wasBlinking)
    end
    tracked[key] = nil
end


local function clearAll(playerIndex)
    for key, _ in pairs(tracked) do
        clearOutline(key, playerIndex)
    end
end


function thermal.scan(plObj)
    if not thermal.enabled or not plObj then return end

    local now = getTimestampMs()
    if now - lastScanMs < thermal.scanIntervalMs then return end
    lastScanMs = now

    local playerIndex = plObj:getPlayerNum()
    local cell = getCell()
    if not cell then return end

    local seenThisScan = {}

    local thermalOnZombies = not SandboxVars.NightVisionChucked or SandboxVars.NightVisionChucked.ThermalOnZombies ~= false
    if thermalOnZombies then
        local zombies = cell:getZombieList()
        if zombies then
            for i = 0, zombies:size() - 1 do
                local zombie = zombies:get(i)
                if zombie then
                    local distance = zombie:DistToProper(plObj)
                    local square = zombie:getSquare()
                    if square and distance <= thermal.scanRadius and square:isCanSee(playerIndex) then
                        local key = tostring(zombie)
                        seenThisScan[key] = true
                        applyOutline(zombie, playerIndex)
                    end
                end
            end
        end
    end

    local players = IsoPlayer.getPlayers()
    if players then
        for i = 0, players:size() - 1 do
            local other = players:get(i)
            if other and other ~= plObj then
                local distance = other:DistToProper(plObj)
                local square = other:getSquare()
                if square and distance <= thermal.scanRadius and square:isCanSee(playerIndex) then
                    local key = tostring(other)
                    seenThisScan[key] = true
                    applyOutline(other, playerIndex)
                end
            end
        end
    end

    for key, _ in pairs(tracked) do
        if not seenThisScan[key] then
            clearOutline(key, playerIndex)
        end
    end
end


function thermal.setEnabled(plObj, enabled)
    thermal.enabled = enabled
    if not enabled and plObj then
        clearAll(plObj:getPlayerNum())
    end
end


return thermal
