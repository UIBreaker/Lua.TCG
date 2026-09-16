local UI = {}

-- Color constants
UI.COLORS = {
    bg = { 0.08, 0.12, 0.11, 1 },
    felt = { 0.10, 0.18, 0.14, 1 },
    panelBg = { 0.12, 0.16, 0.18, 0.95 },
    panelBorder = { 0.25, 0.35, 0.38, 1 },
    cardBg = { 0.98, 0.98, 0.98, 1 },
    cardBorder = { 0.75, 0.78, 0.82, 1 },
    cardSelectedBorder = { 0.95, 0.8, 0.1, 1 },
    textLight = { 0.95, 0.96, 0.98, 1 },
    textDark = { 0.15, 0.15, 0.18, 1 },
    textMuted = { 0.68, 0.74, 0.80, 1 },
    chipsBlue = { 0.18, 0.55, 0.92, 1 },
    multRed = { 0.92, 0.22, 0.28, 1 },
    xmultGold = { 0.95, 0.72, 0.12, 1 },
    goldYellow = { 0.98, 0.85, 0.25, 1 },
    hpGreen = { 0.2, 0.8, 0.3, 1 },
    hpRed = { 0.85, 0.2, 0.2, 1 },
    bossPurple = { 0.85, 0.25, 0.8, 1 },
    btnPlay = { 0.18, 0.55, 0.92, 1 },
    btnDiscard = { 0.88, 0.28, 0.22, 1 },
    btnConfirm = { 0.18, 0.70, 0.38, 1 },
    btnSpecial = { 0.95, 0.75, 0.18, 1 },
    btnDestruct = { 0.82, 0.22, 0.24, 1 },
    btnNormal = { 0.22, 0.28, 0.35, 1 },
}

UI.fonts = {}

function UI.sanitizeText(str)
    if type(str) ~= "string" then return str end
    -- Strip UTF-8 variation selectors U+FE0E and U+FE0F that cause tofu squares in Love2D FreeType
    local s = str:gsub("\239\184\142", ""):gsub("\239\184\143", "")
    return s
end

local utf8 = require("utf8")
function UI.truncateUtf8(str, maxChars)
    if type(str) ~= "string" then return "" end
    maxChars = maxChars or 35
    local ok, len = pcall(utf8.len, str)
    if not ok or not len or len <= maxChars then return str end
    local okOffset, byteOffset = pcall(utf8.offset, str, maxChars + 1)
    if okOffset and byteOffset then
        return str:sub(1, byteOffset - 1) .. "..."
    end
    return str
end

local VN_LOWER_TO_UPPER = {
    ["a"] = "A", ["à"] = "À", ["á"] = "Á", ["ả"] = "Ả", ["ã"] = "Ã", ["ạ"] = "Ạ",
    ["ă"] = "Ă", ["ằ"] = "Ằ", ["ắ"] = "Ắ", ["ẳ"] = "Ẳ", ["ẵ"] = "Ẵ", ["ặ"] = "Ặ",
    ["â"] = "Â", ["ầ"] = "Ầ", ["ấ"] = "Ấ", ["ẩ"] = "Ẩ", ["ẫ"] = "Ẫ", ["ậ"] = "Ậ",
    ["đ"] = "Đ",
    ["e"] = "E", ["è"] = "È", ["é"] = "É", ["ẻ"] = "Ẻ", ["ẽ"] = "Ẽ", ["ẹ"] = "Ẹ",
    ["ê"] = "Ê", ["ề"] = "Ề", ["ế"] = "Ế", ["ể"] = "Ể", ["ễ"] = "Ễ", ["ệ"] = "Ệ",
    ["i"] = "I", ["ì"] = "Ì", ["í"] = "Í", ["ỉ"] = "Ỉ", ["ĩ"] = "Ĩ", ["ị"] = "Ị",
    ["o"] = "O", ["ò"] = "Ò", ["ó"] = "Ó", ["ỏ"] = "Ỏ", ["õ"] = "Õ", ["ọ"] = "Ọ",
    ["ô"] = "Ô", ["ồ"] = "Ồ", ["ố"] = "Ố", ["ổ"] = "Ổ", ["ỗ"] = "Ỗ", ["ộ"] = "Ộ",
    ["ơ"] = "Ơ", ["ờ"] = "Ờ", ["ớ"] = "Ớ", ["ở"] = "Ở", ["ỡ"] = "Ỡ", ["ợ"] = "Ợ",
    ["u"] = "U", ["ù"] = "Ù", ["ú"] = "Ú", ["ủ"] = "Ủ", ["ũ"] = "Ũ", ["ụ"] = "Ụ",
    ["ư"] = "Ư", ["ừ"] = "Ừ", ["ứ"] = "Ứ", ["ử"] = "Ử", ["ữ"] = "Ữ", ["ự"] = "Ự",
    ["y"] = "Y", ["ỳ"] = "Ỳ", ["ý"] = "Ý", ["ỷ"] = "Ỷ", ["ỹ"] = "Ỹ", ["ỵ"] = "Ỵ",
}

function UI.toUpperUtf8(str)
    if type(str) ~= "string" or str == "" then return str or "" end
    local res = str
    for low, upp in pairs(VN_LOWER_TO_UPPER) do
        if #low > 1 then
            res = res:gsub(low, upp)
        end
    end
    return res:upper()
end

function UI.initFonts()
    local fontPath = "fonts/arial.ttf"
    local function loadFont(size)
        local ok, font = pcall(love.graphics.newFont, fontPath, size)
        if not (ok and font) then
            font = love.graphics.newFont(size)
        end
        -- Setup fallback fonts for symbols & emoji
        local okSym, symFont = pcall(love.graphics.newFont, "fonts/seguisym.ttf", size)
        local okEmj, emjFont = pcall(love.graphics.newFont, "C:/Windows/Fonts/seguiemj.ttf", size)
        local fallbacks = {}
        if okSym and symFont then table.insert(fallbacks, symFont) end
        if okEmj and emjFont then table.insert(fallbacks, emjFont) end
        if #fallbacks > 0 and font.setFallbacks then
            pcall(function() font:setFallbacks(unpack(fallbacks)) end)
        end
        return font
    end

    UI.fonts.tiny = loadFont(12)
    UI.fonts.small = loadFont(14)
    UI.fonts.regular = loadFont(17)
    UI.fonts.medium = loadFont(22)
    UI.fonts.large = loadFont(28)
    UI.fonts.title = loadFont(36)
    UI.fonts.huge = loadFont(48)
    UI.fonts.logo = loadFont(92)
end

function UI.drawRoundedRect(mode, x, y, w, h, r)
    r = r or 6
    love.graphics.rectangle(mode, x, y, w, h, r, r)
end

-- Procedural vector drawing for card faction and suit symbols
function UI.drawSuitSymbol(suit, cx, cy, size, customColor)
    love.graphics.push("all")
    if customColor then
        love.graphics.setColor(customColor)
    end

    local s = suit or "aurelia"

    -- 1. ☀️ AURELIA (Phe Ánh Sáng / Hearts alias)
    if s == "aurelia" or s == "hearts" then
        -- Central radiant sun circle
        local r = size * 0.22
        love.graphics.circle("fill", cx, cy, r)

        -- 8 Sun rays bursting outwards
        local rayOuter = size * 0.46
        local rayInner = size * 0.25
        local rayHalfW = size * 0.08
        local angles = { 0, math.pi / 4, math.pi / 2, 3 * math.pi / 4, math.pi, 5 * math.pi / 4, 3 * math.pi / 2, 7 * math.pi / 4 }
        for _, ang in ipairs(angles) do
            local cosA = math.cos(ang)
            local sinA = math.sin(ang)
            local perpX = -sinA * rayHalfW
            local perpY = cosA * rayHalfW

            local tipX = cx + cosA * rayOuter
            local tipY = cy + sinA * rayOuter
            local b1X = cx + cosA * rayInner + perpX
            local b1Y = cy + sinA * rayInner + perpY
            local b2X = cx + cosA * rayInner - perpX
            local b2Y = cy + sinA * rayInner - perpY

            love.graphics.polygon("fill", { b1X, b1Y, tipX, tipY, b2X, b2Y })
        end

    -- 2. 🌲 ELARIS (Phe Thiên Nhiên / Clubs alias)
    elseif s == "elaris" or s == "clubs" then
        -- Tree trunk
        local tw = size * 0.12
        local th = size * 0.22
        love.graphics.rectangle("fill", cx - tw / 2, cy + size * 0.22, tw, th)

        -- 3 Layered triangular evergreen foliage
        -- Top tier
        love.graphics.polygon("fill", {
            cx, cy - size * 0.46,
            cx + size * 0.24, cy - size * 0.14,
            cx - size * 0.24, cy - size * 0.14
        })
        -- Middle tier
        love.graphics.polygon("fill", {
            cx, cy - size * 0.22,
            cx + size * 0.34, cy + size * 0.06,
            cx - size * 0.34, cy + size * 0.06
        })
        -- Bottom tier
        love.graphics.polygon("fill", {
            cx, cy - size * 0.02,
            cx + size * 0.44, cy + size * 0.24,
            cx - size * 0.44, cy + size * 0.24
        })

    -- 3. 🔥 VHAROS (Phe Hắc Ám / Spades alias)
    elseif s == "vharos" or s == "spades" then
        -- Dark leaping flame with dynamic horns/curls
        local flamePoly = {
            cx, cy - size * 0.48,           -- top main peak
            cx + size * 0.18, cy - size * 0.26,
            cx + size * 0.38, cy - size * 0.12,  -- right sub-flame
            cx + size * 0.32, cy + size * 0.15,
            cx + size * 0.18, cy + size * 0.44,  -- bottom right base
            cx - size * 0.18, cy + size * 0.44,  -- bottom left base
            cx - size * 0.32, cy + size * 0.15,
            cx - size * 0.38, cy - size * 0.12,  -- left sub-flame
            cx - size * 0.18, cy - size * 0.26
        }
        love.graphics.polygon("fill", flamePoly)

        -- Inner brighter flame core
        love.graphics.setColor(1, 1, 1, 0.45)
        local innerFlame = {
            cx, cy - size * 0.28,
            cx + size * 0.14, cy + size * 0.06,
            cx + size * 0.08, cy + size * 0.32,
            cx - size * 0.08, cy + size * 0.32,
            cx - size * 0.14, cy + size * 0.06
        }
        love.graphics.polygon("fill", innerFlame)

    -- 4. ⚔️ VALORIA (Phe Nhân Loại / Diamonds alias)
    elseif s == "valoria" or s == "diamonds" then
        -- Crossed swords
        local halfBlade = size * 0.44
        local bladeW = size * 0.08

        -- Sword 1 (TL to BR)
        love.graphics.push()
        love.graphics.translate(cx, cy)
        love.graphics.rotate(math.pi / 4)
        -- Blade
        love.graphics.polygon("fill", {
            0, -halfBlade,
            bladeW / 2, -halfBlade * 0.8,
            bladeW / 2, halfBlade * 0.5,
            -bladeW / 2, halfBlade * 0.5,
            -bladeW / 2, -halfBlade * 0.8
        })
        -- Crossguard
        love.graphics.rectangle("fill", -size * 0.18, halfBlade * 0.5, size * 0.36, size * 0.06)
        -- Hilt & Pommel
        love.graphics.rectangle("fill", -size * 0.04, halfBlade * 0.56, size * 0.08, size * 0.18)
        love.graphics.circle("fill", 0, halfBlade * 0.78, size * 0.06)
        love.graphics.pop()

        -- Sword 2 (TR to BL)
        love.graphics.push()
        love.graphics.translate(cx, cy)
        love.graphics.rotate(-math.pi / 4)
        -- Blade
        love.graphics.polygon("fill", {
            0, -halfBlade,
            bladeW / 2, -halfBlade * 0.8,
            bladeW / 2, halfBlade * 0.5,
            -bladeW / 2, halfBlade * 0.5,
            -bladeW / 2, -halfBlade * 0.8
        })
        -- Crossguard
        love.graphics.rectangle("fill", -size * 0.18, halfBlade * 0.5, size * 0.36, size * 0.06)
        -- Hilt & Pommel
        love.graphics.rectangle("fill", -size * 0.04, halfBlade * 0.56, size * 0.08, size * 0.18)
        love.graphics.circle("fill", 0, halfBlade * 0.78, size * 0.06)
        love.graphics.pop()

        -- Central Shield Boss
        love.graphics.setColor(1, 1, 1, 0.6)
        love.graphics.circle("fill", cx, cy, size * 0.12)
    end

    love.graphics.pop()
end

function UI.drawButton(btn, isHovered, isPressed)
    if not btn or btn.invisible then return end
    if not btn.x or not btn.y or not btn.w or not btn.h then return end

    -- 1. Auto-resolve hover & pressed states if omitted
    if isHovered == nil then
        local mx = UI.virtualMouseX
        local my = UI.virtualMouseY
        if not mx and love.mouse and love.mouse.getPosition then
            mx, my = love.mouse.getPosition()
        end
        if mx and my then
            isHovered = (mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h)
        else
            isHovered = false
        end
    end
    if isPressed == nil then
        isPressed = (btn.isPressed == true) or (btn.id and btn.id == UI.currentPressedBtnId)
    else
        isPressed = isPressed or (btn.isPressed == true) or (btn.id and btn.id == UI.currentPressedBtnId)
    end

    -- 2. Spring Scale Animation (Hover expansion 1.06x, Click shrink 0.94x)
    btn.animScale = btn.animScale or 1.0
    local targetScale = 1.0
    if btn.disabled then
        targetScale = 1.0
    elseif isPressed then
        targetScale = 0.94
    elseif isHovered then
        targetScale = 1.06
    end
    btn.animScale = btn.animScale + (targetScale - btn.animScale) * 0.28

    -- 3. Mechanical Depression Animation (Instant snap down, spring release)
    btn.pressProgress = btn.pressProgress or 0
    if isPressed and not btn.disabled then
        btn.pressProgress = 1.0
    else
        btn.pressProgress = btn.pressProgress * 0.65
        if btn.pressProgress < 0.01 then btn.pressProgress = 0 end
    end

    -- 4. 3D Mouse Tilt (Perspective shear based on cursor offset from center)
    btn.tiltX = btn.tiltX or 0
    btn.tiltY = btn.tiltY or 0
    if isHovered and not btn.disabled then
        local mx = UI.virtualMouseX
        local my = UI.virtualMouseY
        if not mx and love.mouse and love.mouse.getPosition then
            mx, my = love.mouse.getPosition()
        end
        if mx and my then
            local tx, ty = UI.calculateTilt(mx, my, btn.x, btn.y, btn.w, btn.h)
            btn.tiltX = btn.tiltX + (tx - btn.tiltX) * 0.25
            btn.tiltY = btn.tiltY + (ty - btn.tiltY) * 0.25
        end
    else
        btn.tiltX = btn.tiltX * 0.72
        btn.tiltY = btn.tiltY * 0.72
        if math.abs(btn.tiltX) < 0.001 then btn.tiltX = 0 end
        if math.abs(btn.tiltY) < 0.001 then btn.tiltY = 0 end
    end

    -- 5. Extrusion Depth & Corner Radius
    local depth = 0
    if not btn.disabled then
        if btn.depth then
            depth = btn.depth
        elseif btn.h <= 24 then
            depth = 2
        elseif btn.h <= 36 then
            depth = 3
        elseif btn.h <= 55 then
            depth = 5
        else
            depth = 6
        end
    end
    local r = btn.cornerRadius or math.min(8, math.max(4, math.floor(btn.h * 0.2)))
    local depressY = math.floor(btn.pressProgress * math.max(0, depth - 1) + 0.5)

    -- 6. Color Scheme & Disabled State Handling
    local baseCol = btn.color or UI.COLORS.btnNormal
    local faceColor, baseColor, borderColor, textColor
    if btn.disabled then
        faceColor = { 0.22, 0.25, 0.29, 0.88 }
        baseColor = { 0.16, 0.18, 0.21, 0.88 }
        borderColor = { 0.15, 0.17, 0.20, 0.70 }
        textColor = { 0.48, 0.52, 0.56, 0.85 }
    else
        local bright = isHovered and 1.15 or 1.0
        faceColor = {
            math.min(1.0, baseCol[1] * bright),
            math.min(1.0, baseCol[2] * bright),
            math.min(1.0, baseCol[3] * bright),
            baseCol[4] or 1
        }
        baseColor = {
            baseCol[1] * 0.40,
            baseCol[2] * 0.40,
            baseCol[3] * 0.40,
            baseCol[4] or 1
        }
        if isHovered then
            borderColor = { 1.0, 1.0, 1.0, 0.98 }
        else
            borderColor = { 0.06, 0.08, 0.10, 0.88 }
        end
        textColor = btn.textColor or { 1.0, 1.0, 1.0, 1.0 }
    end

    -- 7. Render Transformation
    local cx = btn.x + btn.w / 2
    local cy = btn.y + btn.h / 2

    love.graphics.push()
    love.graphics.translate(cx, cy)
    love.graphics.scale(btn.animScale, btn.animScale)
    if btn.tiltX ~= 0 or btn.tiltY ~= 0 then
        love.graphics.shear(btn.tiltX * 0.045, btn.tiltY * 0.045)
    end
    love.graphics.translate(-cx, -cy)

    -- A. Extruded 3D Base (Chân nút phía dưới dày 3-6px)
    if depth > 0 then
        love.graphics.setColor(baseColor)
        UI.drawRoundedRect("fill", btn.x, btn.y + 2, btn.w, btn.h - 2, r)

        love.graphics.setColor(0.04, 0.05, 0.07, 0.92)
        love.graphics.setLineWidth(1.5)
        UI.drawRoundedRect("line", btn.x, btn.y + 2, btn.w, btn.h - 2, r)
    end

    -- B. Button Face (Mặt trên nút)
    local faceY = btn.y + depressY
    local faceH = btn.h - depth
    if isPressed and depth > 0 then
        faceH = math.max(4, faceH - 1)
    end

    love.graphics.setColor(faceColor)
    UI.drawRoundedRect("fill", btn.x, faceY, btn.w, faceH, r)

    -- Face Top Glossy Highlight (Phản quang mép trên)
    if not btn.disabled and faceH > 10 then
        love.graphics.setColor(1, 1, 1, isHovered and 0.26 or 0.16)
        local hlH = math.max(2, math.min(6, math.floor(faceH * 0.22)))
        UI.drawRoundedRect("fill", btn.x + 2, faceY + 1, btn.w - 4, hlH, math.max(2, r - 2))
    end

    -- Face Bottom Inset Shadow (Rãnh phân tách Face và Base)
    if not btn.disabled and depth > 0 and faceH > 12 then
        love.graphics.setColor(0, 0, 0, 0.24)
        UI.drawRoundedRect("fill", btn.x + 2, faceY + faceH - 3, btn.w - 4, 2, math.max(1, r - 2))
    end

    -- Face Outline (Sáng trắng khi hover, viền đen pixel khi bình thường)
    love.graphics.setLineWidth(isHovered and not btn.disabled and 2.0 or 1.5)
    love.graphics.setColor(borderColor)
    UI.drawRoundedRect("line", btn.x, faceY, btn.w, faceH, r)

    -- C. Typography, Labels, Subtitles & Hotkey Badges
    local font = btn.font or UI.fonts.regular or love.graphics.getFont()
    love.graphics.setFont(font)

    local rawText = btn.text or ""
    local cleanText = UI.sanitizeText(rawText)
    if not btn.preserveCase then
        cleanText = UI.toUpperUtf8(cleanText)
    end

    if btn.isMultiLine and btn.sub then
        local f1 = UI.fonts.large or font
        local f2 = UI.fonts.medium or font
        -- Line 1
        love.graphics.setFont(f1)
        local l1W = f1:getWidth(cleanText)
        local l1Y = faceY + faceH * 0.24
        love.graphics.setColor(0.04, 0.04, 0.06, 0.95)
        love.graphics.print(cleanText, btn.x + (btn.w - l1W) / 2, l1Y + 1.5)
        love.graphics.setColor(textColor)
        love.graphics.print(cleanText, btn.x + (btn.w - l1W) / 2, l1Y)

        -- Subtitle
        local subText = UI.sanitizeText(btn.sub or "")
        if not btn.preserveCase then subText = UI.toUpperUtf8(subText) end
        love.graphics.setFont(f2)
        local subW = f2:getWidth(subText)
        local subY = faceY + faceH * 0.52
        love.graphics.setColor(0.04, 0.04, 0.06, 0.95)
        love.graphics.print(subText, btn.x + (btn.w - subW) / 2, subY + 1.5)
        love.graphics.setColor(btn.disabled and textColor or { 0.92, 0.94, 0.98, 0.95 })
        love.graphics.print(subText, btn.x + (btn.w - subW) / 2, subY)
    elseif btn.sub then
        local fMain = font
        local fSub = UI.fonts.small or font
        love.graphics.setFont(fMain)
        local mainW = fMain:getWidth(cleanText)
        local mainY = faceY + faceH * 0.16
        love.graphics.setColor(0.04, 0.04, 0.06, 0.95)
        love.graphics.print(cleanText, btn.x + (btn.w - mainW) / 2, mainY + 1.5)
        love.graphics.setColor(textColor)
        love.graphics.print(cleanText, btn.x + (btn.w - mainW) / 2, mainY)

        local subText = UI.sanitizeText(btn.sub or "")
        if not btn.preserveCase then subText = UI.toUpperUtf8(subText) end
        love.graphics.setFont(fSub)
        local subW = fSub:getWidth(subText)
        local subY = faceY + faceH * 0.56
        love.graphics.setColor(0.04, 0.04, 0.06, 0.95)
        love.graphics.print(subText, btn.x + (btn.w - subW) / 2, subY + 1.5)
        love.graphics.setColor(btn.disabled and textColor or { 0.92, 0.94, 0.98, 0.92 })
        love.graphics.print(subText, btn.x + (btn.w - subW) / 2, subY)
    else
        -- Check for newline
        if cleanText:find("\n") then
            local rawLines = {}
            for l in cleanText:gmatch("([^\r\n]*)") do
                table.insert(rawLines, l)
            end
            if #rawLines > 1 and rawLines[#rawLines] == "" then
                table.remove(rawLines)
            end
            local lineH = font:getHeight()
            local lineSpacing = 2
            local totalH = #rawLines * lineH + (#rawLines - 1) * lineSpacing
            local curY = faceY + (faceH - totalH) / 2
            for _, line in ipairs(rawLines) do
                if #line > 0 then
                    local lw = font:getWidth(line)
                    local lx = btn.x + (btn.w - lw) / 2
                    -- Shadow
                    love.graphics.setColor(0.04, 0.04, 0.06, 0.95)
                    love.graphics.print(line, lx, curY + 1.5)
                    -- Face text
                    love.graphics.setColor(textColor)
                    love.graphics.print(line, lx, curY)
                end
                curY = curY + lineH + lineSpacing
            end
        else
            -- Single line: Check for hotkey bracket like [Space], [D], [R], [Tab], [Esc]
            local hotkey = cleanText:match("%[([^%]]+)%]")
            if hotkey and not btn.noHotkeyBadge then
                local prefix = cleanText:gsub("%s*%[[^%]]+%]%s*", "")
                local pW = (#prefix > 0) and font:getWidth(prefix) or 0
                local badgeFont = (font == UI.fonts.large or font == UI.fonts.huge) and (UI.fonts.medium or font) 
                                  or (font == UI.fonts.medium and (UI.fonts.small or font) or (UI.fonts.tiny or font))
                local kw = math.max(20, badgeFont:getWidth(hotkey) + 12)
                local kh = math.max(16, badgeFont:getHeight() + 4)
                local gap = (pW > 0) and 8 or 0
                local totalW = pW + gap + kw
                local startX = btn.x + (btn.w - totalW) / 2
                local textY = faceY + (faceH - font:getHeight()) / 2
                local badgeY = faceY + (faceH - kh) / 2

                if pW > 0 then
                    -- Main text shadow
                    love.graphics.setFont(font)
                    love.graphics.setColor(0.04, 0.04, 0.06, 0.95)
                    love.graphics.print(prefix, startX, textY + 1.5)
                    -- Main text
                    love.graphics.setColor(textColor)
                    love.graphics.print(prefix, startX, textY)
                end

                -- Keycap Badge
                local bx = startX + pW + gap
                -- Keycap Base / Depressed casing
                love.graphics.setColor(0.06, 0.08, 0.10, 0.95)
                UI.drawRoundedRect("fill", bx, badgeY + 1, kw, kh, 3)
                -- Keycap Face
                love.graphics.setColor(0.14, 0.18, 0.22, 0.95)
                UI.drawRoundedRect("fill", bx, badgeY, kw, kh - 1, 3)
                -- Keycap Top Highlight
                love.graphics.setColor(1, 1, 1, 0.22)
                love.graphics.line(bx + 2, badgeY + 1, bx + kw - 2, badgeY + 1)
                -- Keycap Border
                love.graphics.setLineWidth(1)
                love.graphics.setColor(0.36, 0.44, 0.52, 0.92)
                UI.drawRoundedRect("line", bx, badgeY, kw, kh, 3)
                -- Keycap Text
                love.graphics.setFont(badgeFont)
                local kwText = badgeFont:getWidth(hotkey)
                local khText = badgeFont:getHeight()
                local ktx = bx + (kw - kwText) / 2
                local kty = badgeY + (kh - khText) / 2
                love.graphics.setColor(0, 0, 0, 0.95)
                love.graphics.print(hotkey, ktx, kty + 1)
                love.graphics.setColor(UI.COLORS.goldYellow or { 0.98, 0.85, 0.25, 1 })
                love.graphics.print(hotkey, ktx, kty)
            else
                -- Standard single line text
                local textW = font:getWidth(cleanText)
                local textH = font:getHeight()
                local tx = btn.x + (btn.w - textW) / 2
                local ty = faceY + (faceH - textH) / 2
                -- Shadow
                love.graphics.setColor(0.04, 0.04, 0.06, 0.95)
                love.graphics.print(cleanText, tx, ty + 1.5)
                -- Face text
                love.graphics.setColor(textColor)
                love.graphics.print(cleanText, tx, ty)
            end
        end
    end

    -- Alert exclamation badge on right side
    if btn.alert then
        local badgeX = btn.x + btn.w - 18
        local badgeY = faceY + faceH / 2
        love.graphics.setColor(0.85, 0.18, 0.18, 1)
        love.graphics.circle("fill", badgeX, badgeY, 11)
        love.graphics.setColor(1, 1, 1, 0.95)
        love.graphics.setLineWidth(1.5)
        love.graphics.circle("line", badgeX, badgeY, 11)
        love.graphics.setFont(UI.fonts.tiny or font)
        love.graphics.setColor(0, 0, 0, 0.95)
        love.graphics.printf("!", badgeX - 11, badgeY - 6, 22, "center")
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("!", badgeX - 11, badgeY - 7, 22, "center")
    end

    love.graphics.pop()
end

function UI.drawCard(card, x, y, w, h)
    love.graphics.push()
    love.graphics.translate(x + w / 2, y + h / 2)
    if card.rotation and card.rotation ~= 0 then
        love.graphics.rotate(card.rotation)
    end
    -- Pseudo-3D perspective tilt
    if (card.tiltX and card.tiltX ~= 0) or (card.tiltY and card.tiltY ~= 0) then
        love.graphics.shear((card.tiltX or 0) * 0.12, (card.tiltY or 0) * 0.12)
    end
    local s = card.visualScale or 1
    local sx = (card.scaleX or card.scale or 1) * s
    local sy = (card.scaleY or card.scale or 1) * s
    love.graphics.scale(sx, sy)
    love.graphics.translate(-w / 2, -h / 2)

    -- Dynamic Drop Shadow based on tilt & elevation
    local isLifted = (s > 1.05) or (card.isLifted == true)
    local shOffX = 4 + (card.tiltX or 0) * 10
    local shOffY = (isLifted and 14 or 6) + (card.tiltY or 0) * 10
    local shAlpha = isLifted and 0.45 or 0.32
    love.graphics.setColor(0, 0, 0, shAlpha)
    UI.drawRoundedRect("fill", shOffX, shOffY, w, h, 8)

    -- Card background
    love.graphics.setColor(UI.COLORS.cardBg)
    UI.drawRoundedRect("fill", 0, 0, w, h, 8)

    -- Border
    love.graphics.setLineWidth(card.selected and 3.5 or 2)
    if card.selected then
        love.graphics.setColor(UI.COLORS.cardSelectedBorder)
    elseif card.hovered then
        love.graphics.setColor(UI.COLORS.chipsBlue)
    else
        love.graphics.setColor(UI.COLORS.cardBorder)
    end
    UI.drawRoundedRect("line", 0, 0, w, h, 8)

    -- Face-down Card Drawing (The Fish boss ability)
    if card.faceDown then
        love.graphics.setColor(0.14, 0.18, 0.24, 1)
        UI.drawRoundedRect("fill", 2, 2, w - 4, h - 4, 6)

        love.graphics.setColor(0.35, 0.45, 0.6, 0.8)
        love.graphics.setLineWidth(1.5)
        UI.drawRoundedRect("line", 5, 5, w - 10, h - 10, 5)

        love.graphics.setFont(UI.fonts.large)
        love.graphics.setColor(0.65, 0.78, 0.95, 0.9)
        love.graphics.printf("?", 0, h / 2 - 18, w, "center")

        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(0.5, 0.6, 0.75, 0.8)
        love.graphics.printf("ÚP MẶT", 0, h / 2 + 14, w, "center")

        love.graphics.pop()
        return
    end

    -- Gilded inner frame for equipped cards (subtle, elegant golden foil inlay)
    local eqCount = (card.equipments and #card.equipments) or 0
    if eqCount > 0 then
        love.graphics.setLineWidth(1.5)
        love.graphics.setColor(0.88, 0.74, 0.26, 0.85)
        UI.drawRoundedRect("line", 3, 3, w - 6, h - 6, 6)

        -- Corner ornamental notches
        love.graphics.setColor(0.95, 0.82, 0.35, 0.95)
        love.graphics.line(5, 8, 8, 5)
        love.graphics.line(w - 5, 8, w - 8, 5)
        love.graphics.line(5, h - 8, 8, h - 5)
        love.graphics.line(w - 5, h - 8, w - 8, h - 5)
    end

    local suitColor = card.color or { 0.2, 0.2, 0.2, 1 }

    -- Top-left rank
    love.graphics.setColor(suitColor)
    love.graphics.setFont(UI.fonts.large)
    love.graphics.print(card.rankName, 8, 4)

    -- Top-left small suit icon
    UI.drawSuitSymbol(card.suit, 15, 40, 16, suitColor)

    -- Center big suit symbol
    UI.drawSuitSymbol(card.suit, w / 2, h / 2 - 2, 46, suitColor)

    -- Bottom-right rank
    love.graphics.setColor(suitColor)
    love.graphics.setFont(UI.fonts.regular)
    local rk = card.rankName
    local rkW = UI.fonts.regular:getWidth(rk)
    love.graphics.print(rk, w - rkW - 8, h - 25)

    -- Role text at lower center
    local roleText = card.roleName
    if not roleText and card.rank then
        local Deck = require("src.deck")
        local role = Deck.getCardRole(card.rank)
        roleText = role.name
    end
    if roleText then
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(0.4, 0.45, 0.5, 0.9)
        love.graphics.printf(roleText, 0, h - 39, w, "center")
    end

    -- Base Chip badge at bottom center
    love.graphics.setColor(UI.COLORS.chipsBlue[1], UI.COLORS.chipsBlue[2], UI.COLORS.chipsBlue[3], 0.9)
    UI.drawRoundedRect("fill", (w - 38) / 2, h - 22, 38, 18, 4)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(UI.fonts.small)
    local chipStr = "+" .. card.baseChips
    local cW = UI.fonts.small:getWidth(chipStr)
    love.graphics.print(chipStr, (w - cW) / 2, h - 20)

    -- 5 Faceted Gemstone Sockets across the top edge
    local socketCount = 5
    local socketR = 5.2
    local socketGap = 13
    local socketStartX = (w - (socketCount * socketGap - 3)) / 2 + 3
    local socketY = 9

    for s = 1, socketCount do
        local sx = socketStartX + (s - 1) * socketGap
        local eq = card.equipments and card.equipments[s]

        if eq then
            -- Slotted Gemstone with jewelry bezel & prong setting
            local gc = eq.color or UI.COLORS.goldYellow

            -- 1. Outer golden prong rim
            love.graphics.setColor(0.95, 0.82, 0.28, 0.9)
            love.graphics.circle("fill", sx, socketY, socketR + 1.2)

            -- 2. Dark setting shadow
            love.graphics.setColor(0.12, 0.12, 0.14, 0.8)
            love.graphics.circle("fill", sx, socketY, socketR)

            -- 3. Gemstone body
            love.graphics.setColor(gc[1], gc[2], gc[3], 0.95)
            love.graphics.circle("fill", sx, socketY, socketR - 0.4)

            -- 4. Facet lower shading (depth)
            love.graphics.setColor(0, 0, 0, 0.35)
            love.graphics.arc("fill", sx, socketY, socketR - 0.4, 0, math.pi)

            -- 5. Inner facet ring
            love.graphics.setColor(1, 1, 1, 0.35)
            love.graphics.setLineWidth(1)
            love.graphics.circle("line", sx, socketY, (socketR - 0.4) * 0.55)

            -- 6. Specular highlight glint (sparkle reflection)
            love.graphics.setColor(1, 1, 1, 0.95)
            love.graphics.circle("fill", sx - 1.6, socketY - 1.6, 1.4)

            -- 7. Four golden prongs at corners
            love.graphics.setColor(0.98, 0.88, 0.35, 1)
            love.graphics.circle("fill", sx - socketR, socketY, 0.9)
            love.graphics.circle("fill", sx + socketR, socketY, 0.9)
            love.graphics.circle("fill", sx, socketY - socketR, 0.9)
            love.graphics.circle("fill", sx, socketY + socketR, 0.9)
        else
            -- Empty metallic setting socket
            love.graphics.setColor(0.24, 0.27, 0.32, 0.9)
            love.graphics.circle("fill", sx, socketY, socketR + 0.8)

            love.graphics.setColor(0.11, 0.13, 0.16, 0.95)
            love.graphics.circle("fill", sx, socketY, socketR - 0.5)

            love.graphics.setLineWidth(1)
            love.graphics.setColor(0.55, 0.60, 0.68, 0.5)
            love.graphics.circle("line", sx, socketY, socketR - 0.5)

            -- Center indent
            love.graphics.setColor(0.06, 0.08, 0.10, 0.85)
            love.graphics.circle("fill", sx, socketY, 1.1)
        end
    end

    love.graphics.pop()
end

function UI.drawMonsterHpBar(x, y, w, h, currentHp, maxHp, damageLagHp)
    -- Background bar
    love.graphics.setColor(0.12, 0.14, 0.16, 0.95)
    UI.drawRoundedRect("fill", x, y, w, h, 6)

    local maxH = math.max(1, maxHp)
    -- Damage lag bar (yellow/red trailing bar)
    if damageLagHp and damageLagHp > currentHp then
        local lagRatio = math.min(1.0, math.max(0.0, damageLagHp / maxH))
        love.graphics.setColor(0.9, 0.45, 0.1, 0.85)
        UI.drawRoundedRect("fill", x, y, w * lagRatio, h, 6)
    end

    -- Current HP Fill (Green fading to red)
    local ratio = math.min(1.0, math.max(0.0, currentHp / maxH))
    if ratio > 0 then
        if ratio > 0.5 then
            love.graphics.setColor(UI.COLORS.hpGreen)
        elseif ratio > 0.25 then
            love.graphics.setColor(UI.COLORS.goldYellow)
        else
            love.graphics.setColor(UI.COLORS.hpRed)
        end
        UI.drawRoundedRect("fill", x, y, w * ratio, h, 6)
    end

    -- Border
    love.graphics.setLineWidth(2)
    love.graphics.setColor(0.35, 0.45, 0.5, 1)
    UI.drawRoundedRect("line", x, y, w, h, 6)

    -- HP Text inside bar
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(1, 1, 1, 1)
    local hpText = currentHp .. " / " .. maxHp .. " HP"
    local tw = UI.fonts.small:getWidth(hpText)
    love.graphics.print(hpText, x + (w - tw) / 2, y + (h - 16) / 2)
end

function UI.drawPlayerHpBar(x, y, w, h, currentHp, maxHp, shield)
    currentHp = math.max(0, currentHp or 100)
    maxHp = maxHp or 100
    shield = shield or 0

    -- Background
    love.graphics.setColor(0.1, 0.13, 0.16, 0.95)
    UI.drawRoundedRect("fill", x, y, w, h, 6)

    -- Fill bar
    local pct = math.min(1.0, math.max(0.0, currentHp / maxHp))
    local fillW = math.floor((w - 4) * pct)
    if fillW > 0 then
        if pct > 0.5 then
            love.graphics.setColor(0.2, 0.8, 0.4, 0.95)
        elseif pct > 0.25 then
            love.graphics.setColor(0.95, 0.8, 0.2, 0.95)
        else
            love.graphics.setColor(0.85, 0.2, 0.2, 0.95)
        end
        UI.drawRoundedRect("fill", x + 2, y + 2, fillW, h - 4, 4)
    end

    -- Border
    love.graphics.setColor(0.3, 0.4, 0.48, 1)
    love.graphics.setLineWidth(1.5)
    UI.drawRoundedRect("line", x, y, w, h, 6)

    -- Text
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(1, 1, 1, 1)
    local hpText = "MÁU: " .. currentHp .. " / " .. maxHp .. " HP"
    if shield > 0 then
        hpText = hpText .. " (GIÁP: +" .. shield .. ")"
    end
    local tw = UI.fonts.small:getWidth(hpText)
    love.graphics.print(hpText, x + (w - tw) / 2, y + (h - 16) / 2)
end

-- Format numbers with commas (e.g. 1,234,567) or scientific e-notation (e.g. 1.234e12)
function UI.formatNumber(num)
    if not num then return "0" end
    local absVal = math.abs(num)
    local sign = (num < 0) and "-" or ""

    -- Scientific e-notation when >= 1 Billion (1e9)
    if absVal >= 1e9 then
        local exp = math.floor(math.log10(absVal))
        local mantissa = absVal / (10 ^ exp)
        return string.format("%s%.3fe%d", sign, mantissa, exp)
    end

    if absVal % 1 ~= 0 and absVal < 100 then
        return string.format("%s%.1f", sign, absVal)
    end

    local n = math.floor(absVal)
    local formatted = tostring(n)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return sign .. formatted
end

-- Draw Balatro-style hover badge above hand card
function UI.drawCardHoverBadge(card, cx, cy, cardW, cardH)
    if not card or card.faceDown then return end
    local bw = 108
    local bh = 46
    local bx = cx + (cardW - bw) / 2
    local by = cy - bh - 8

    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.4)
    UI.drawRoundedRect("fill", bx + 2, by + 2, bw, bh, 6)

    -- Background
    love.graphics.setColor(0.10, 0.12, 0.16, 0.96)
    UI.drawRoundedRect("fill", bx, by, bw, bh, 6)
    love.graphics.setLineWidth(1.5)
    love.graphics.setColor(0.40, 0.50, 0.62, 0.9)
    UI.drawRoundedRect("line", bx, by, bw, bh, 6)

    -- Top Section: Rank & Suit
    love.graphics.setFont(UI.fonts.small)
    local sColor = UI.COLORS[card.suit] or UI.COLORS.goldYellow
    love.graphics.setColor(sColor)
    local suitShort = (card.suit == "aurelia") and "Thánh" or ((card.suit == "elaris") and "Mộc" or ((card.suit == "vharos") and "Quỷ" or "Thép"))
    local titleStr = UI.sanitizeText(card.rankName .. " " .. (card.suitSymbol or "") .. " (" .. suitShort .. ")")
    love.graphics.printf(titleStr, bx, by + 4, bw, "center")

    -- Divider
    love.graphics.setColor(0.25, 0.32, 0.40, 0.7)
    love.graphics.line(bx + 6, by + 24, bx + bw - 6, by + 24)

    -- Bottom Section: +Chips / Equipment bonus
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(UI.COLORS.chipsBlue)
    local chipStr = "+" .. (card.baseChips or 0) .. " chip"
    if card.equipments and #card.equipments > 0 then
        local eqMult = 0
        for _, eq in ipairs(card.equipments) do
            if eq.addedMult then eqMult = eqMult + eq.addedMult end
        end
        if eqMult > 0 then
            chipStr = chipStr .. " / +" .. eqMult .. "m"
        end
    end
    love.graphics.printf(chipStr, bx, by + 28, bw, "center")
end

-- Center-anchored dynamic scaling number rendering
function UI.drawAnimatedNumber(text, bx, by, bw, bh, color, scaleFactor)
    scaleFactor = scaleFactor or 1.0
    local font = UI.fonts.huge
    if font:getWidth(text) > (bw - 16) then
        font = UI.fonts.large
    end
    if font:getWidth(text) > (bw - 16) then
        font = UI.fonts.medium
    end
    love.graphics.setFont(font)
    love.graphics.setColor(color)

    local cx = bx + bw / 2
    local cy = by + 22 + (bh - 22) / 2
    local tw = font:getWidth(text)
    local th = font:getHeight()

    love.graphics.push()
    love.graphics.translate(cx, cy)
    love.graphics.scale(scaleFactor, scaleFactor)
    love.graphics.print(text, -tw / 2, -th / 2)
    love.graphics.pop()
end

function UI.calculateTilt(mx, my, cx, cy, w, h)
    if not mx or not my or not cx or not cy then return 0, 0 end
    local cardCenterX = cx + (w or 100) / 2
    local cardCenterY = cy + (h or 140) / 2
    local normX = math.max(-1, math.min(1, (mx - cardCenterX) / ((w or 100) * 0.5)))
    local normY = math.max(-1, math.min(1, (my - cardCenterY) / ((h or 140) * 0.5)))
    return normX, normY
end

return UI
