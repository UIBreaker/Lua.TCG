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

function UI.initFonts()
    local fontPath = "fonts/arial.ttf"
    local function loadFont(size)
        local ok, font = pcall(love.graphics.newFont, fontPath, size)
        if ok and font then
            return font
        end
        return love.graphics.newFont(size)
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

-- Procedural vector drawing for card suit symbols
function UI.drawSuitSymbol(suit, cx, cy, size, customColor)
    love.graphics.push("all")
    if customColor then
        love.graphics.setColor(customColor)
    end

    if suit == "hearts" then
        local r = size * 0.26
        love.graphics.circle("fill", cx - size * 0.22, cy - size * 0.10, r)
        love.graphics.circle("fill", cx + size * 0.22, cy - size * 0.10, r)
        local poly = {
            cx - size * 0.46, cy - size * 0.04,
            cx + size * 0.46, cy - size * 0.04,
            cx, cy + size * 0.48
        }
        love.graphics.polygon("fill", poly)
        love.graphics.rectangle("fill", cx - size * 0.22, cy - size * 0.10, size * 0.44, size * 0.14)

    elseif suit == "diamonds" then
        local poly = {
            cx, cy - size * 0.48,
            cx + size * 0.36, cy,
            cx, cy + size * 0.48,
            cx - size * 0.36, cy
        }
        love.graphics.polygon("fill", poly)

    elseif suit == "clubs" then
        local r = size * 0.22
        love.graphics.circle("fill", cx, cy - size * 0.18, r)
        love.graphics.circle("fill", cx - size * 0.22, cy + size * 0.08, r)
        love.graphics.circle("fill", cx + size * 0.22, cy + size * 0.08, r)
        love.graphics.circle("fill", cx, cy + size * 0.04, r * 0.85)
        local stem = {
            cx - size * 0.06, cy + size * 0.05,
            cx + size * 0.06, cy + size * 0.05,
            cx + size * 0.18, cy + size * 0.48,
            cx - size * 0.18, cy + size * 0.48
        }
        love.graphics.polygon("fill", stem)

    elseif suit == "spades" then
        local poly = {
            cx, cy - size * 0.48,
            cx - size * 0.46, cy + size * 0.08,
            cx + size * 0.46, cy + size * 0.08
        }
        love.graphics.polygon("fill", poly)
        local r = size * 0.24
        love.graphics.circle("fill", cx - size * 0.22, cy + size * 0.12, r)
        love.graphics.circle("fill", cx + size * 0.22, cy + size * 0.12, r)
        love.graphics.rectangle("fill", cx - size * 0.22, cy, size * 0.44, size * 0.15)
        local stem = {
            cx - size * 0.06, cy + size * 0.08,
            cx + size * 0.06, cy + size * 0.08,
            cx + size * 0.18, cy + size * 0.48,
            cx - size * 0.18, cy + size * 0.48
        }
        love.graphics.polygon("fill", stem)
    end

    love.graphics.pop()
end

function UI.drawButton(btn, isHovered)
    local col = btn.color or UI.COLORS.btnNormal
    if btn.disabled then
        love.graphics.setColor(col[1] * 0.35, col[2] * 0.35, col[3] * 0.35, 0.7)
    elseif isHovered then
        love.graphics.setColor(math.min(1, col[1] * 1.2), math.min(1, col[2] * 1.2), math.min(1, col[3] * 1.2), 1)
    else
        love.graphics.setColor(col[1], col[2], col[3], col[4] or 1)
    end

    UI.drawRoundedRect("fill", btn.x, btn.y, btn.w, btn.h, 8)

    -- Border
    love.graphics.setLineWidth(2)
    if isHovered and not btn.disabled then
        love.graphics.setColor(1, 1, 1, 0.9)
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
    local textW = font:getWidth(btn.text)
    local textH = font:getHeight()
    love.graphics.print(btn.text, btn.x + (btn.w - textW) / 2, btn.y + (btn.h - textH) / 2)
end

function UI.drawCard(card, x, y, w, h)
    love.graphics.push()
    love.graphics.translate(x + w / 2, y + h / 2)
    if card.rotation and card.rotation ~= 0 then
        love.graphics.rotate(card.rotation)
    end
    love.graphics.scale(card.scale or 1, card.scale or 1)
    love.graphics.translate(-w / 2, -h / 2)

    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.35)
    UI.drawRoundedRect("fill", 3, 4, w, h, 8)

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

    -- Base Chip badge at bottom center
    love.graphics.setColor(UI.COLORS.chipsBlue[1], UI.COLORS.chipsBlue[2], UI.COLORS.chipsBlue[3], 0.9)
    UI.drawRoundedRect("fill", (w - 38) / 2, h - 22, 38, 18, 4)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(UI.fonts.small)
    local chipStr = "+" .. card.baseChips
    local cW = UI.fonts.small:getWidth(chipStr)
    love.graphics.print(chipStr, (w - cW) / 2, h - 20)

    -- Draw 5 Equipment Sockets across the top edge
    local socketCount = 5
    local socketSize = 5
    local socketStartX = (w - (socketCount * 12 - 4)) / 2
    local socketY = 8

    for s = 1, socketCount do
        local sx = socketStartX + (s - 1) * 12
        local eq = card.equipments and card.equipments[s]
        if eq then
            love.graphics.setColor(eq.color or UI.COLORS.goldYellow)
            love.graphics.circle("fill", sx + 4, socketY, socketSize)
            love.graphics.setColor(1, 1, 1, 0.9)
            love.graphics.circle("line", sx + 4, socketY, socketSize)
        else
            love.graphics.setColor(0.7, 0.7, 0.75, 0.5)
            love.graphics.circle("line", sx + 4, socketY, socketSize - 1)
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

return UI
