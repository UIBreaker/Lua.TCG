local Rng = {}

local generator = love and love.math and love.math.newRandomGenerator and love.math.newRandomGenerator(1) or nil
local fallbackState = 1

function Rng.seed(seed)
    seed = math.floor(tonumber(seed) or 1)
    if generator then
        generator:setSeed(seed)
    else
        fallbackState = seed % 2147483647
        if fallbackState <= 0 then fallbackState = 1 end
    end
end

local function unitRandom()
    if generator then return generator:random() end
    fallbackState = (fallbackState * 48271) % 2147483647
    return fallbackState / 2147483647
end

function Rng.random(minimum, maximum)
    if minimum == nil then return unitRandom() end
    if maximum == nil then
        maximum = minimum
        minimum = 1
    end
    minimum = math.floor(minimum)
    maximum = math.floor(maximum)
    if maximum < minimum then minimum, maximum = maximum, minimum end
    return minimum + math.floor(unitRandom() * (maximum - minimum + 1))
end

function Rng.getState()
    if generator and generator.getState then return generator:getState() end
    return tostring(fallbackState)
end

function Rng.setState(state)
    if not state then return false end
    if generator and generator.setState then
        local ok = pcall(generator.setState, generator, state)
        return ok
    end
    local numericState = tonumber(state)
    if not numericState then return false end
    fallbackState = numericState
    return true
end

return Rng
