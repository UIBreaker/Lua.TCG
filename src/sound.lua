local Sound = {}

local sounds = {}
local enabled = true

local function generateSound(duration, sampleRate, generator)
    local sampleCount = math.floor(duration * sampleRate)
    local soundData = love.sound.newSoundData(sampleCount, sampleRate, 16, 1)
    for i = 0, sampleCount - 1 do
        local t = i / sampleRate
        local sample = generator(t, duration)
        -- Clamp between -1.0 and 1.0
        sample = math.max(-1.0, math.min(1.0, sample))
        soundData:setSample(i, sample)
    end
    return love.audio.newSource(soundData, "static")
end

function Sound.init()
    if not love.sound or not love.audio then
        enabled = false
        return
    end

    local success, err = pcall(function()
        local rate = 44100

        -- 1. Card Click / Select (Soft crisp pop)
        sounds.card_select = generateSound(0.04, rate, function(t, d)
            local env = (1 - t / d) ^ 2
            local freq = 480 + (t / d) * 320
            return env * 0.4 * math.sin(2 * math.pi * freq * t)
        end)

        -- 2. Card Deselect (Lower soft pop)
        sounds.card_deselect = generateSound(0.03, rate, function(t, d)
            local env = (1 - t / d) ^ 2
            local freq = 360 - (t / d) * 100
            return env * 0.3 * math.sin(2 * math.pi * freq * t)
        end)

        -- 3. Card Discard / Deal (Swoosh)
        sounds.card_deal = generateSound(0.08, rate, function(t, d)
            local env = (1 - t / d) ^ 3
            local noise = (love.math.random() * 2 - 1)
            local sine = math.sin(2 * math.pi * (200 + t * 400) * t)
            return env * 0.35 * (noise * 0.5 + sine * 0.5)
        end)

        -- 4. Chip Tick (Clear crystal bell ping)
        sounds.chip_tick = generateSound(0.07, rate, function(t, d)
            local env = math.exp(-t * 35)
            local s1 = math.sin(2 * math.pi * 980 * t)
            local s2 = math.sin(2 * math.pi * 1960 * t) * 0.3
            return env * 0.45 * (s1 + s2)
        end)

        -- 5. Mult Pop (Punchy ascending thump)
        sounds.mult_pop = generateSound(0.1, rate, function(t, d)
            local env = math.exp(-t * 22)
            local freq = 320 + (t / d) * 200
            local s = math.sin(2 * math.pi * freq * t)
            return env * 0.55 * s
        end)

        -- 6. XMult Explosion (Boom + sparkle)
        sounds.xmult_boom = generateSound(0.3, rate, function(t, d)
            local env = math.exp(-t * 12)
            local bass = math.sin(2 * math.pi * (140 - t * 180) * t)
            local noise = (love.math.random() * 2 - 1) * math.exp(-t * 25)
            local sparkle = math.sin(2 * math.pi * 1760 * t) * math.exp(-t * 15) * 0.3
            return env * 0.7 * (bass * 0.6 + noise * 0.25 + sparkle)
        end)

        -- 7. Win Fanfare
        sounds.round_win = generateSound(0.45, rate, function(t, d)
            local env = (1 - t / d)
            local note = 440
            if t > 0.30 then note = 880
            elseif t > 0.20 then note = 659.25
            elseif t > 0.10 then note = 554.37
            end
            local s = math.sin(2 * math.pi * note * t)
            return env * 0.5 * s
        end)

        -- 8. Game Over tone
        sounds.game_over = generateSound(0.5, rate, function(t, d)
            local env = (1 - t / d)
            local freq = 220 - (t / d) * 110
            return env * 0.5 * (math.sin(2 * math.pi * freq * t) + math.sin(2 * math.pi * (freq * 1.5) * t) * 0.5)
        end)
    end)

    if not success then
        print("[Sound] Init warning: audio synthesizer disabled (" .. tostring(err) .. ")")
        enabled = false
    end
end

function Sound.play(name)
    if not enabled then return end
    local s = sounds[name]
    if s then
        pcall(function()
            s:stop()
            s:play()
        end)
    end
end

return Sound
