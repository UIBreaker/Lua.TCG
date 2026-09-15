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
    btnPlay = { 0.18, 0.68, 0.42, 1 },
    btnDiscard = { 0.85, 0.32, 0.25, 1 },
    btnNormal = { 0.22, 0.28, 0.35, 1 },
}

UI.fonts = {}

function UI.sanitizeText(str)
    if type(str) ~= "string" then return str end
    -- Strip UTF-8 variation selectors U+FE0E and U+FE0F that cause tofu squares in Love2D FreeType
    local s = str:gsub("\239\184\142", ""):gsub("\239\184\143", "")
    return s
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
    btn.animScale = btn.animScale or 1.0
    local targetScale = 1.0
    if btn.disabled then
        targetScale = 1.0
    elseif isPressed then
        targetScale = 0.94
    elseif isHovered then
        targetScale = 1.04
    end
    btn.animScale = btn.animScale + (targetScale - btn.animScale) * 0.25

    local cx = btn.x + btn.w / 2
    local cy = btn.y + btn.h / 2

    love.graphics.push()
    love.graphics.translate(cx, cy)
    love.graphics.scale(btn.animScale, btn.animScale)
    love.graphics.translate(-cx, -cy)

    local col = btn.color or UI.COLORS.btnNormal
    if btn.disabled then
        love.graphics.setColor(col[1] * 0.35, col[2] * 0.35, col[3] * 0.35, 0.7)
    elseif isHovered then
        love.graphics.setColor(math.min(1, col[1] * 1.25), math.min(1, col[2] * 1.25), math.min(1, col[3] * 1.25), 1)
    else
        love.graphics.setColor(col[1], col[2], col[3], col[4] or 1)
    end

    if isHovered and not btn.disabled then
        love.graphics.setColor(0, 0, 0, 0.35)
        UI.drawRoundedRect("fill", btn.x + 2, btn.y + 4, btn.w, btn.h, 8)
        love.graphics.setColor(math.min(1, col[1] * 1.25), math.min(1, col[2] * 1.25), math.min(1, col[3] * 1.25), 1)
    end

    UI.drawRoundedRect("fill", btn.x, btn.y, btn.w, btn.h, 8)

    -- Border
    love.graphics.setLineWidth(2)
    if isHovered and not btn.disabled then
        love.graphics.setColor(1, 1, 1, 0.95)
    else
        love.graphics.setColor(0, 0, 0, 0.35)
    end
    UI.drawRoundedRect("line", btn.x, btn.y, btn.w, btn.h, 8)

    -- Text
    local font = btn.font or UI.fonts.regular or love.graphics.getFont()
    love.graphics.setFont(font)
    if btn.disabled then
        love.graphics.setColor(0.6, 0.6, 0.6, 0.8)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end
    local cleanText = UI.sanitizeText(btn.text or "")
    local textW = font:getWidth(cleanText)
    local textH = font:getHeight()
    love.graphics.print(cleanText, btn.x + (btn.w - textW) / 2, btn.y + (btn.h - textH) / 2)

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
