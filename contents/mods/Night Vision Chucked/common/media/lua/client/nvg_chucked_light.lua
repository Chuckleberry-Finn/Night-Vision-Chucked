local nvLight = {}

nvLight.radius = 16
nvLight.r = 0.33
nvLight.g = 1
nvLight.b = 0.10

local UPDATE_INTERVAL_MS = 200

local currentLight = nil
local lastX, lastY, lastZ = nil, nil, nil
local lastCheckMs = 0


local function applyPowerLevel(light, powerLevel, brightness)
    local pl = powerLevel or 1
    local b = brightness or 1
    light:setR(nvLight.r * pl * b)
    light:setG(nvLight.g * pl * b)
    light:setB(nvLight.b * pl * b)
end


function nvLight.update(plObj, powerLevel, radius, brightness)
    if not plObj then
        nvLight.remove()
        return
    end

    local activeRadius = radius or nvLight.radius

    local now = getTimestampMs()
    if currentLight and (now - lastCheckMs) < UPDATE_INTERVAL_MS then
        return
    end
    lastCheckMs = now

    local cell = getCell()
    if not cell then return end

    local square = plObj:getCurrentSquare()
    if not square then return end

    local dx = plObj:getForwardDirectionX()
    local dy = plObj:getForwardDirectionY()
    local shift = activeRadius / 3

    local lx = math.floor(square:getX() + dx * shift + 0.5)
    local ly = math.floor(square:getY() + dy * shift + 0.5)
    local lz = square:getZ()

    if currentLight and lx == lastX and ly == lastY and lz == lastZ then
        currentLight:setRadius(activeRadius)
        applyPowerLevel(currentLight, powerLevel, brightness)
        return
    end

    if currentLight then
        cell:removeLamppost(currentLight)
        currentLight = nil
    end

    currentLight = cell:addLamppost(lx, ly, lz, nvLight.r, nvLight.g, nvLight.b, activeRadius)
    applyPowerLevel(currentLight, powerLevel, brightness)
    lastX, lastY, lastZ = lx, ly, lz
end


function nvLight.remove()
    local cell = getCell()
    if cell and currentLight then
        cell:removeLamppost(currentLight)
    end
    currentLight = nil
    lastX, lastY, lastZ = nil, nil, nil
end


return nvLight
