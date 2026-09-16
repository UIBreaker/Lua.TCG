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

        -- 9. Jackpot chime (Bright rapid casino victory chimes)
        sounds.jackpot = generateSound(0.55, rate, function(t, d)
            local env = (1 - t / d) ^ 1.5
            local note = 523.25 -- C5
            if t > 0.40 then note = 1046.50 -- C6
            elseif t > 0.28 then note = 783.99 -- G5
            elseif t > 0.14 then note = 659.25 -- E5
            end
            local chime = math.sin(2 * math.pi * note * t) + 0.35 * math.sin(2 * math.pi * note * 2 * t)
            return env * 0.55 * chime
        end)

        -- 10. UI Button Hover (Subtle soft blip)
        sounds.ui_hover = generateSound(0.025, rate, function(t, d)
            local env = (1 - t / d) ^ 2
            local freq = 620 + (t / d) * 180
            return env * 0.18 * math.sin(2 * math.pi * freq * t)
        end)

        -- 11. UI Button Click (Tactile mechanical clack + woody switch thud)
        sounds.ui_click = generateSound(0.05, rate, function(t, d)
            -- A. Sharp mechanical snap / clack transient (0 to 6ms)
            local snapNoise = (love.math.random() * 2 - 1) * math.exp(-t * 160) * 0.45
            local snapChirp = math.sin(2 * math.pi * (2400 - t * 16000) * t) * math.exp(-t * 110) * 0.35

            -- B. Tactile woody switch thud body (360-480 Hz bottom-out)
            local bodyFreq = 420 * math.exp(-t * 16)
            local body = math.sin(2 * math.pi * bodyFreq * t) + 0.35 * math.sin(4 * math.pi * bodyFreq * t)
            local bodyEnv = math.exp(-t * 40)

            -- C. Secondary micro tactile release ping around 10ms
            local ping = 0
            if t > 0.010 then
                local pt = t - 0.010
                ping = math.sin(2 * math.pi * 1350 * pt) * math.exp(-pt * 85) * 0.18
            end

            return (snapNoise + snapChirp) * 0.55 + body * bodyEnv * 0.50 + ping
        end)

        -- 12. Shop Buy (Crystal coin chimes + paper grab snap)
        sounds.shop_buy = generateSound(0.38, rate, function(t, d)
            local env = math.exp(-t * 12)
            -- Ascending bell arpeggio notes
            local note = 1318.51 -- E6
            if t > 0.18 then note = 2637.02 -- E7
            elseif t > 0.11 then note = 1975.53 -- B6
            elseif t > 0.05 then note = 1661.22 -- G#6
            end
            local bell = math.sin(2 * math.pi * note * t) + 0.4 * math.sin(2 * math.pi * note * 2.75 * t)
            local grabSnap = (t < 0.04) and ((love.math.random() * 2 - 1) * 0.35) or 0
            return env * 0.5 * bell + grabSnap
        end)

        -- 13. Shop Reroll (Crisp card riffle shuffle & deck slide)
        sounds.shop_reroll = generateSound(0.26, rate, function(t, d)
            local progress = t / d
            local env = math.sin(progress * math.pi) ^ 0.7
            -- Rapid riffle tick bursts
            local tickPhase = (t * 65) % 1.0
            local tick = (tickPhase < 0.3) and 1.0 or 0.15
            local noise = (love.math.random() * 2 - 1) * tick
            local freq = 380 + progress * 720
            local swoosh = math.sin(2 * math.pi * freq * t) * 0.4
            return env * 0.5 * (noise * 0.6 + swoosh * 0.4)
        end)

        -- 14. Can't Afford (Dull error thock)
        sounds.cant_afford = generateSound(0.12, rate, function(t, d)
            local env = math.exp(-t * 32)
            local freq = 160 - (t / d) * 70
            local thock = math.sin(2 * math.pi * freq * t) + 0.3 * math.sin(2 * math.pi * (freq * 0.5) * t)
            return env * 0.45 * thock
        end)

        -- 15. Booster Pack Open (Foil tear + magic shimmer)
        sounds.pack_open = generateSound(0.42, rate, function(t, d)
            local env = math.exp(-t * 9)
            local tearNoise = (t < 0.09) and ((love.math.random() * 2 - 1) * (1 - t / 0.09)) or 0
            local shimmerFreq = 1200 + (t / d) * 1600
            local shimmer = math.sin(2 * math.pi * shimmerFreq * t) * 0.5 + 0.25 * math.sin(2 * math.pi * (shimmerFreq * 1.5) * t)
            return env * 0.45 * (tearNoise * 0.7 + shimmer * 0.5)
        end)
    end)

    if not success then
        print("[Sound] Init warning: audio synthesizer disabled (" .. tostring(err) .. ")")
        enabled = false
    end
end

local masterVolume = 0.8
if love and love.audio and love.audio.setVolume then
    love.audio.setVolume(masterVolume)
end

function Sound.setVolume(vol)
    masterVolume = math.max(0, math.min(1.0, vol or 0.8))
    if love.audio and love.audio.setVolume then
        love.audio.setVolume(masterVolume)
    end
end

function Sound.getVolume()
    return masterVolume
end

function Sound.play(name, pitch)
    if not enabled then return end
    local s = sounds[name]
    if s then
        pcall(function()
            s:stop()
            if pitch and s.setPitch then
                s:setPitch(math.max(0.2, math.min(3.0, pitch)))
            elseif s.setPitch then
                s:setPitch(1.0)
            end
            s:play()
        end)
    end
end

return Sound
