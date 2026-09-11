local Deck = require("src.deck")
local Poker = require("src.poker")
local Deities = require("src.deities")
local Scoring = require("src.scoring")
local Shop = require("src.shop")
local Sound = require("src.sound")
local UI = require("src.ui")
local Monster = require("src.monster")
local Equipment = require("src.equipment")
local Map = require("src.map")
local Events = require("src.events")

io.stdout:setvbuf("no")
local isCaptureMode = false
for _, a in ipairs(arg or {}) do
    if a == "--test" then
        require("test_system")
        love.event.quit(0)
    elseif a == "--capture" then
        isCaptureMode = true
    end
end
local Capture = isCaptureMode and require("capture_screens") or nil

-- Game States: "menu", "map", "playing", "scoring", "shop", "event", "boss_deity", "chest", "socketing", "gameover", "victory"
local state = "menu"

-- Virtual Resolution
local V_WIDTH = 1280
local V_HEIGHT = 720
local scale = 1
local offsetX = 0
local offsetY = 0

-- Run data
local game = {
    selectedSuit = "hearts",
    round = 1,
    act = 1,
    map = nil,
    currentNodeId = nil,
    currentEvent = nil,
    eventOutcomeText = nil,
    bossDeityDraft = {},
    unlockedHands = { high_card = true }, -- Initially ONLY High Card is unlocked!
    monster = nil,
    handsRemaining = 4,
    maxHands = 4,
    discardsRemaining = 3,
    maxDiscards = 3,
    gold = 6,
    deities = {},
    persistentDeck = {}, -- Master persistent deck of cards
    deck = {},
    discardPile = {},
    hand = {},
    selectedIndices = {},
    sortMode = "rank",
    discardBuffs = { chips = 0, mult = 0, xMult = 1.0, bonusDamagePct = 0 },
}

local shopData = nil
local chestRewards = {}
local pendingEquipment = nil
local socketingReturnState = "shop"

-- Right-Click Card Inspector Modal
local inspectCardModal = nil

-- Handbook Modal State (Compendium of Unlocked Hands)
local isHandbookOpen = false

-- Shop Equipment Transfer
local isShopTransferOpen = false
local transferSourceCard = nil
local transferSourceEqIndex = nil
local transferMessage = nil

-- Rest Site & Forge State
local restStateData = {
    chosenAction = nil, -- "rest", "forge", nil
    selectedCard = nil,
    message = nil,
}

-- Treasure Site State
local treasureRewards = {}

-- Deck Viewer Modal State
local isDeckViewerOpen = false
local deckViewerFilter = "all" -- "all", "rank", "suit", "equipped"

-- Scoring Animation State
local anim = {
    active = false,
    timer = 0,
    scoringData = nil,
    currentStepIndex = 1,
    displayChips = 0,
    displayMult = 0,
    displayXMult = 1.0,
    stepTimer = 0,
    playedCards = {},
    floatingTexts = {},
    monsterDefeated = false,
    earnedGold = 0,
    damageDealt = 0,
}

-- Screen shake
local screenShake = 0

-- UI Elements
local buttons = {}
local hoveredDeityTooltip = nil
local hoveredCardTooltip = nil

--------------------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------------------

local function updateScale()
    local winW, winH = love.graphics.getDimensions()
    local scaleX = winW / V_WIDTH
    local scaleY = winH / V_HEIGHT
    scale = math.min(scaleX, scaleY)
    offsetX = (winW - V_WIDTH * scale) / 2
    offsetY = (winH - V_HEIGHT * scale) / 2
end

local function toVirtual(mx, my)
    return (mx - offsetX) / scale, (my - offsetY) / scale
end

local function syncCardSelections()
    for _, c in ipairs(game.hand) do
        c.selected = false
    end
    for _, idx in ipairs(game.selectedIndices) do
        if game.hand[idx] then
            game.hand[idx].selected = true
        end
    end
end

local function getAllDeckCards()
    if game.persistentDeck and #game.persistentDeck > 0 then
        return game.persistentDeck
    end
    local list = {}
    local seen = {}
    for _, pile in ipairs({ game.hand, game.deck, game.discardPile }) do
        for _, c in ipairs(pile) do
            if not seen[c.id] then
                seen[c.id] = true
                table.insert(list, c)
            end
        end
    end
    return list
end

local function clearAllSelections()
    game.selectedIndices = {}
    for _, c in ipairs(game.hand) do
        c.selected = false
    end
    for _, c in ipairs(game.deck) do
        c.selected = false
    end
    for _, c in ipairs(game.discardPile) do
        c.selected = false
    end
    if game.persistentDeck then
        for _, c in ipairs(game.persistentDeck) do
            c.selected = false
        end
    end
end

local function getCardGridPos(i, totalCards, cardW, cardH, gapX, gapY, maxCols, baseY)
    cardW = cardW or 100
    cardH = cardH or 145
    gapX = gapX or 16
    gapY = gapY or 32
    maxCols = maxCols or 8
    baseY = baseY or 240

    if totalCards <= maxCols then
        local totalW = totalCards * cardW + math.max(0, totalCards - 1) * gapX
        local startX = (V_WIDTH - totalW) / 2
        return startX + (i - 1) * (cardW + gapX), baseY, cardW, cardH
    else
        local cols = math.min(totalCards, maxCols)
        local totalW = cols * cardW + math.max(0, cols - 1) * gapX
        local startX = (V_WIDTH - totalW) / 2
        local col = (i - 1) % maxCols
        local row = math.floor((i - 1) / maxCols)
        return startX + col * (cardW + gapX), baseY - 45 + row * (cardH + gapY), cardW, cardH
    end
end

local function getMaxSelectableCards()
    local maxCount = 1
    for handId, isUnlocked in pairs(game.unlockedHands) do
        if isUnlocked and Poker.HAND_TYPES[handId:upper()] then
            local req = Poker.HAND_TYPES[handId:upper()].requiredCards or 1
            if req > maxCount then
                maxCount = req
            end
        end
    end
    if game.monster and game.monster.isBoss and game.monster.bossData and game.monster.bossData.debuffId == "max_4_cards" then
        maxCount = math.min(maxCount, 4)
    end
    return maxCount
end

local function startMonsterEncounter(floor, isBossNode, isEliteNode)
    game.round = floor or 1
    game.monsterEncounterCount = game.monsterEncounterCount or 1
    game.monster = Monster.create(game.round, isBossNode, isEliteNode, game.monsterEncounterCount)
    game.handsRemaining = game.maxHands

    -- Valoria Passive: +1 Discard per combat
    if game.selectedFaction == "valoria" or game.selectedSuit == "valoria" then
        game.discardsRemaining = game.maxDiscards + 1
    else
        game.discardsRemaining = game.maxDiscards
    end

    -- Apply Boss modifier if any
    if game.monster.isBoss and game.monster.bossData and game.monster.bossData.applyModifier then
        game.monster.bossData.applyModifier(game)
    end

    -- Trigger deities onRoundStart
    for _, d in ipairs(game.deities) do
        if d.onRoundStart then
            local res = d.onRoundStart(game)
            if res and res.addDiscards then
                game.discardsRemaining = game.discardsRemaining + res.addDiscards
            end
            if res and res.addHands then
                game.handsRemaining = game.handsRemaining + res.addHands
            end
        end
    end

    -- Restore persistentDeck back to original baseRank and rebuild active deck
    if not game.persistentDeck or #game.persistentDeck == 0 then
        game.persistentDeck = Deck.createStarterDeck(game.selectedFaction or game.selectedSuit or "aurelia")
    end
    Deck.restoreDeck(game.persistentDeck)
    game.masterDeck = game.persistentDeck
    game.deck = {}
    for _, c in ipairs(game.persistentDeck) do
        table.insert(game.deck, Deck.cloneCard(c))
    end
    game.discardPile = {}
    game.hand = {}
    game.discardBuffs = { chips = 0, mult = 0, xMult = 1.0, bonusDamagePct = 0 }
    Deck.shuffle(game.deck)
    clearAllSelections()

    -- Elaris Passive: Sức Sống Rừng Già (draw up to 9 cards instead of 8)
    local maxHandSize = (game.selectedFaction == "elaris" or game.selectedSuit == "elaris") and 9 or 8
    while #game.hand < maxHandSize and #game.deck > 0 do
        local drawn = table.remove(game.deck)
        drawn.selected = false
        table.insert(game.hand, drawn)
    end

    if game.sortMode == "rank" then
        Deck.sortByRank(game.hand)
    else
        Deck.sortBySuit(game.hand)
    end

    clearAllSelections()
    syncCardSelections()

    state = "playing"
    Sound.play("card_deal")
end

local function startNewGame(chosenFaction)
    game.selectedFaction = chosenFaction or "aurelia"
    game.selectedSuit = game.selectedFaction
    game.monsterEncounterCount = 1
    game.round = 1
    game.act = 1
    game.gold = 6
    game.maxHands = 4
    game.maxDiscards = (game.selectedFaction == "valoria") and 4 or 3
    game.unlockedHands = { high_card = true }
    game.deities = {} -- Mới vào game không có vị thần nào hết!
    game.hand = {}
    game.discardPile = {}
    game.discardBuffs = { chips = 0, mult = 0, xMult = 1.0, bonusDamagePct = 0 }

    inspectCardModal = nil
    isShopTransferOpen = false
    isHandbookOpen = false
    transferSourceCard = nil
    transferSourceEqIndex = nil
    transferMessage = nil

    -- 1. Create starter persistent deck of 3 RANDOM cards of the chosen faction
    game.persistentDeck = Deck.createStarterDeck(game.selectedFaction)
    Deck.restoreDeck(game.persistentDeck)
    game.masterDeck = game.persistentDeck

    -- Outside combat, active combat piles are empty
    game.deck = {}
    game.hand = {}
    game.discardPile = {}

    clearAllSelections()
    syncCardSelections()

    -- 2. Generate Act 1 Map (20 floors)
    game.map = Map.generate(1)
    state = "map"
    Sound.play("card_deal")
end

local function getSelectedCards()
    local selected = {}
    for _, idx in ipairs(game.selectedIndices) do
        if game.hand[idx] then
            table.insert(selected, game.hand[idx])
        end
    end
    return selected
end

local function toggleCardSelection(index)
    local found = nil
    for i, idx in ipairs(game.selectedIndices) do
        if idx == index then
            found = i
            break
        end
    end

    if found then
        table.remove(game.selectedIndices, found)
        Sound.play("card_deselect")
    else
        local maxAllowed = getMaxSelectableCards()
        if #game.selectedIndices < maxAllowed then
            table.insert(game.selectedIndices, index)
            Sound.play("card_select")
        else
            if maxAllowed == 1 then
                table.insert(anim.floatingTexts, {
                    text = "Mới vào chỉ đánh được 1 lá ĐƠN THỦ! Mua Sách Bí Tịch tại Shop để mở Đôi, Sảnh, Thùng!",
                    color = UI.COLORS.xmultGold,
                    x = 640,
                    y = 480,
                    alpha = 2.0,
                })
            else
                table.insert(anim.floatingTexts, {
                    text = "Tối đa được chọn " .. maxAllowed .. " lá theo các bí tịch đã mở khóa!",
                    color = UI.COLORS.xmultGold,
                    x = 640,
                    y = 480,
                    alpha = 1.5,
                })
            end
        end
    end
    syncCardSelections()
end

local function discardSelected()
    if #game.selectedIndices == 0 or game.discardsRemaining <= 0 then return end

    -- Check if any discarded card has Free Feather equipment
    local hasFreeDiscard = false
    for _, idx in ipairs(game.selectedIndices) do
        local c = game.hand[idx]
        if c and c.equipments then
            for _, eq in ipairs(c.equipments) do
                if eq.onDiscard and eq.onDiscard(c).freeDiscard then
                    hasFreeDiscard = true
                    break
                end
            end
        end
    end

    table.sort(game.selectedIndices, function(a, b) return a > b end)
    local discardedCards = {}
    for _, idx in ipairs(game.selectedIndices) do
        local card = table.remove(game.hand, idx)
        card.selected = false
        table.insert(discardedCards, card)
    end
    clearAllSelections()

    -- Process Faction Passives on Discard
    game.discardBuffs = game.discardBuffs or { chips = 0, mult = 0, xMult = 1.0, bonusDamagePct = 0 }

    local isVharosFaction = (game.selectedFaction == "vharos" or game.selectedSuit == "vharos")
    local isElarisFaction = (game.selectedFaction == "elaris" or game.selectedSuit == "elaris")
    local isAureliaFaction = (game.selectedFaction == "aurelia" or game.selectedSuit == "aurelia")
    local isValoriaFaction = (game.selectedFaction == "valoria" or game.selectedSuit == "valoria")

    for _, card in ipairs(discardedCards) do
        local suit = card.suit or game.selectedFaction or "aurelia"
        local isAurelia = (suit == "aurelia" or isAureliaFaction)
        local isElaris = (suit == "elaris" or isElarisFaction)
        local isVharos = (suit == "vharos" or isVharosFaction)
        local isValoria = (suit == "valoria" or isValoriaFaction)

        -- 1. ☀️ AURELIA: Thánh Quang Tích Lũy (+6 Chips for Soldier, +12 Chips & +1 Mult for Royal, recycles to deck)
        if isAurelia then
            local isRoyal = (card.rank >= 11)
            local addC = isRoyal and 12 or 6
            local addM = isRoyal and 1 or 0

            game.discardBuffs.chips = (game.discardBuffs.chips or 0) + addC
            game.discardBuffs.mult = (game.discardBuffs.mult or 0) + addM

            -- Blessed card returns to draw deck
            table.insert(game.deck, 1, card)

            local txt = isRoyal and ("☀️ Thánh Quang (" .. card.rankName .. "): +" .. addC .. "c, +" .. addM .. "m!") or ("☀️ Thánh Quang (" .. card.rankName .. "): +" .. addC .. "c!")
            table.insert(anim.floatingTexts, {
                text = txt,
                color = UI.COLORS.goldYellow,
                x = 640,
                y = 440,
                alpha = 2.0,
            })
            Sound.play("chip_tick")

        -- 2. 🌲 ELARIS: Nảy Mầm Tái Sinh (Heal degraded rank by 1 up to baseRank, or +4 Chips if full, recycles to deck)
        elseif isElaris then
            local healed = false
            if card.rank < card.baseRank then
                card.rank = math.min(card.baseRank, card.rank + 1)
                card.rankName = Deck.getRankName(card.rank)
                card.baseChips = Deck.getBaseChips(card.rank)
                card.durability = math.min(1.0, (card.durability or 1.0) + 0.3)
                healed = true
            else
                game.discardBuffs.chips = (game.discardBuffs.chips or 0) + 4
            end
            table.insert(game.deck, 1, card)

            local txt = healed and ("🌲 Phục Hồi: Lá " .. card.rankName .. " khôi phục +1 Rank!") or ("🌲 Nảy Mầm (" .. card.rankName .. "): +4 Chips!")
            table.insert(anim.floatingTexts, {
                text = txt,
                color = { 0.2, 0.85, 0.4, 1 },
                x = 640,
                y = 440,
                alpha = 2.0,
            })
            Sound.play("card_deal")

        -- 3. 🔥 VHAROS: Huyết Tế Bùng Nổ (Sacrifice card to discardPile for 3/6 flat True Damage chip)
        elseif isVharos then
            table.insert(game.discardPile, card)
            local isRoyal = (card.rank >= 11)
            local trueDmg = isRoyal and 6 or 3

            if game.monster and game.monster.hp > 0 then
                local actualDmg, defeated = Monster.takeDamage(game.monster, trueDmg)
                table.insert(anim.floatingTexts, {
                    text = "🔥 Huyết Tế (" .. card.rankName .. "): -" .. actualDmg .. " Sát Thương Chuẩn!",
                    color = { 0.95, 0.25, 0.35, 1 },
                    x = 640,
                    y = 440,
                    alpha = 2.0,
                })
                Sound.play("xmult_boom")
                if defeated then
                    local baseReward = game.monster.isBoss and 15 or (game.monster.isElite and 10 or 4)
                    game.gold = game.gold + baseReward
                    Sound.play("round_win")
                end
            end

        -- 4. ⚔️ VALORIA: Hậu Cần Quân Nhu & Mài Kiếm (+5 Chips for Soldier, +8 Chips & +$1 Gold for Royal, recycles to deck)
        elseif isValoria then
            local isRoyal = (card.rank >= 11)
            local addC = isRoyal and 8 or 5
            game.discardBuffs.chips = (game.discardBuffs.chips or 0) + addC

            local goldAmt = isRoyal and 1 or 0
            if goldAmt > 0 then
                game.gold = game.gold + goldAmt
            end

            table.insert(game.deck, 1, card)

            local txt = isRoyal and ("⚔️ Quân Nhu (" .. card.rankName .. "): +$1 Vàng & +" .. addC .. " Chips!") or ("⚔️ Mài Kiếm (" .. card.rankName .. "): +" .. addC .. " Chips!")
            table.insert(anim.floatingTexts, {
                text = txt,
                color = { 0.35, 0.70, 0.98, 1 },
                x = 640,
                y = 440,
                alpha = 2.0,
            })
            Sound.play("card_deal")
        else
            table.insert(game.discardPile, card)
        end
    end

    if hasFreeDiscard then
        table.insert(anim.floatingTexts, {
            text = "MIỄN PHÍ ĐỔI BÀI (LÔNG VŨ)!",
            color = UI.COLORS.goldYellow,
            x = 640,
            y = 520,
            alpha = 1.5,
        })
    else
        game.discardsRemaining = game.discardsRemaining - 1
    end

    -- Refill hand to maxHandSize (9 for Elaris, 8 for others) while deck has cards
    local maxHandSize = (game.selectedFaction == "elaris" or game.selectedSuit == "elaris") and 9 or 8
    while #game.hand < maxHandSize and #game.deck > 0 do
        local drawn = table.remove(game.deck)
        if drawn then
            drawn.selected = false
            table.insert(game.hand, drawn)
        end
    end

    -- Defeat check if cards are exhausted without defeating monster
    if #game.hand == 0 and #game.deck == 0 and game.monster and game.monster.hp > 0 then
        state = "gameover"
        Sound.play("game_over")
        return
    end

    if game.sortMode == "rank" then
        Deck.sortByRank(game.hand)
    else
        Deck.sortBySuit(game.hand)
    end

    clearAllSelections()
    syncCardSelections()
    Sound.play("card_deal")
end

local function playSelectedHand()
    if #game.selectedIndices == 0 or game.handsRemaining <= 0 then return end

    local playedCards = getSelectedCards()
    local evalResult = Poker.evaluate(playedCards, game.unlockedHands)
    if not evalResult then return end

    -- Ensure played cards don't draw with selection border in scoring animation
    for _, c in ipairs(playedCards) do
        c.selected = false
    end

    -- Deduct hand
    game.handsRemaining = game.handsRemaining - 1

    -- Remove played cards from hand
    table.sort(game.selectedIndices, function(a, b) return a > b end)
    for _, idx in ipairs(game.selectedIndices) do
        local c = table.remove(game.hand, idx)
        c.selected = false
        table.insert(game.discardPile, c)
    end
    clearAllSelections()
    syncCardSelections()

    -- Calculate scoring steps & equipment
    local context = {
        handsRemaining = game.handsRemaining,
        discardsRemaining = game.discardsRemaining,
        round = game.round,
        monster = game.monster,
        discardBuffs = game.discardBuffs,
        selectedSuit = game.selectedSuit,
    }
    local scoreResult = Scoring.calculate(evalResult, game.deities, context)
    -- Reset consumed discard buffs
    game.discardBuffs = { chips = 0, mult = 0, xMult = 1.0, bonusDamagePct = 0 }

    -- Setup scoring animation
    anim.active = true
    anim.timer = 0
    anim.scoringData = scoreResult
    anim.currentStepIndex = 1
    anim.displayChips = scoreResult.baseChips
    anim.displayMult = scoreResult.baseMult
    anim.displayXMult = 1.0
    anim.displayFinalScore = scoreResult.baseChips * scoreResult.baseMult
    anim.activeCardIndex = nil
    anim.scoredCards = {}
    anim.stepLog = evalResult.type.vnName .. ": " .. scoreResult.baseChips .. " Chips × " .. scoreResult.baseMult .. " Mult"
    anim.stepCategory = "TAY BÀI GỐC"
    anim.stepTimer = 0
    anim.playedCards = playedCards
    anim.evalResult = evalResult
    anim.floatingTexts = {}
    anim.monsterDefeated = false
    anim.earnedGold = 0
    anim.damageDealt = 0

    state = "scoring"
    Sound.play("chip_tick")
end

local function generateBossChestRewards()
    chestRewards = {}
    -- Option 1: Cross-suit rare card
    local rewardCard = Deck.createRewardCard(game.selectedSuit)
    table.insert(chestRewards, {
        type = "card",
        card = rewardCard,
        title = "LÁ BÀI NGOẠI LAI: " .. rewardCard.rankName .. " " .. rewardCard.suitName,
        desc = "Thêm một lá bài chất " .. rewardCard.suitName .. " vào bộ bài để đa dạng hóa chiến thuật!",
        color = rewardCard.color,
    })

    -- Option 2 & 3: Random Equipments
    local eq1 = Equipment.getRandomEquipment()
    table.insert(chestRewards, {
        type = "equipment",
        item = eq1,
        title = "TRANG BỊ: " .. eq1.name,
        desc = eq1.desc,
        color = eq1.color,
    })

    local eq2 = Equipment.getRandomEquipment()
    while eq2.id == eq1.id do
        eq2 = Equipment.getRandomEquipment()
    end
    table.insert(chestRewards, {
        type = "equipment",
        item = eq2,
        title = "TRANG BỊ: " .. eq2.name,
        desc = eq2.desc,
        color = eq2.color,
    })
end

--------------------------------------------------------------------------------
-- LÖVE Callbacks
--------------------------------------------------------------------------------

function love.load()
    UI.initFonts()
    Sound.init()
    updateScale()
    shopData = Shop.new()
end

function love.resize(w, h)
    updateScale()
end

function love.update(dt)
    if isCaptureMode and Capture then
        Capture.update(game, {
            startNewGame = startNewGame,
            openDeckViewer = function() isDeckViewerOpen = true end,
            closeDeckViewer = function() isDeckViewerOpen = false end,
            startMonsterEncounter = function(fl, isB)
                startMonsterEncounter(fl, isB)
                state = "playing"
            end,
            openShop = function()
                Shop.refresh(shopData, game)
                state = "shop"
            end,
            openBossDeity = function()
                game.bossDeityDraft = Deities.getBossDraftPool(game.deities, 2)
                state = "boss_deity"
            end,
            openInspector = function(card)
                inspectCardModal = card
            end,
            closeInspector = function()
                inspectCardModal = nil
            end,
            openShopTransfer = function()
                isShopTransferOpen = true
            end,
            closeShopTransfer = function()
                isShopTransferOpen = false
            end,
            openHandbook = function()
                isHandbookOpen = true
            end,
            closeHandbook = function()
                isHandbookOpen = false
            end,
            openRest = function()
                restStateData = { chosenAction = nil, selectedCard = nil, message = nil }
                state = "rest"
            end,
            openSocketing = function(eq)
                pendingEquipment = eq or Equipment.ITEMS.gem_fire
                socketingReturnState = "map"
                state = "socketing"
            end,
            selectCardIndex = function(idx)
                toggleCardSelection(idx)
            end,
        })
    end

    if screenShake > 0 then
        screenShake = math.max(0, screenShake - dt * 15)
    end

    -- Update Map horizontal scrolling camera
    if game.map then
        Map.update(game.map, dt)
    end

    -- Smooth Monster damage lag bar
    if game.monster and game.monster.damageLagHp > game.monster.hp then
        game.monster.damageLagHp = math.max(game.monster.hp, game.monster.damageLagHp - dt * (game.monster.maxHp * 0.75))
    end

    -- Update floating texts
    for i = #anim.floatingTexts, 1, -1 do
        local ft = anim.floatingTexts[i]
        ft.y = ft.y - dt * 40
        ft.alpha = ft.alpha - dt * 1.1
        if ft.alpha <= 0 then
            table.remove(anim.floatingTexts, i)
        end
    end

    -- Scoring Animation Loop
    if state == "scoring" and anim.active then
        anim.stepTimer = anim.stepTimer + dt
        local stepDelay = 0.42

        if anim.stepTimer >= stepDelay then
            anim.stepTimer = 0
            anim.currentStepIndex = anim.currentStepIndex + 1

            local steps = anim.scoringData.steps
            if anim.currentStepIndex <= #steps then
                local st = steps[anim.currentStepIndex]

                if st.type == "base_hand" then
                    anim.activeCardIndex = nil
                    anim.stepCategory = "TAY BÀI GỐC"
                    anim.stepLog = st.vnName .. ": " .. st.chips .. " Chips × " .. st.mult .. " Mult cơ bản"
                    anim.displayChips = st.chips
                    anim.displayMult = st.mult
                    anim.displayFinalScore = st.chips * st.mult

                elseif st.type == "card_scored" then
                    anim.activeCardIndex = st.cardIndex
                    anim.scoredCards = anim.scoredCards or {}
                    anim.scoredCards[st.cardIndex] = { addedChips = st.addedChips, addedMult = st.addedMult }
                    anim.displayChips = anim.displayChips + st.addedChips
                    anim.displayMult = anim.displayMult + st.addedMult
                    anim.displayFinalScore = math.floor(anim.displayChips * anim.displayMult * anim.displayXMult)
                    anim.stepCategory = "LÁ BÀI " .. st.cardIndex .. "/" .. #anim.playedCards
                    local trigStr = ""
                    if st.deityTriggers and #st.deityTriggers > 0 then
                        trigStr = " (" .. st.deityTriggers[1].message .. ")"
                    end
                    anim.stepLog = "Lá " .. st.card.rankName .. st.card.suitSymbol .. ": +" .. st.addedChips .. " Chips" .. (st.addedMult > 0 and (" & +" .. st.addedMult .. " Mult") or "") .. trigStr
                    Sound.play("chip_tick")

                elseif st.type == "equipment_trigger" then
                    anim.activeCardIndex = nil
                    if st.addedChips then
                        anim.displayChips = anim.displayChips + st.addedChips
                        Sound.play("chip_tick")
                    end
                    if st.addedMult then
                        anim.displayMult = anim.displayMult + st.addedMult
                        Sound.play("mult_pop")
                    end
                    anim.displayFinalScore = math.floor(anim.displayChips * anim.displayMult * anim.displayXMult)
                    anim.stepCategory = "HIỆU ỨNG TRANG BỊ"
                    anim.stepLog = st.message

                elseif st.type == "deity_hand" then
                    anim.activeCardIndex = nil
                    if st.addedChips > 0 then
                        anim.displayChips = anim.displayChips + st.addedChips
                        Sound.play("chip_tick")
                    end
                    if st.addedMult > 0 then
                        anim.displayMult = anim.displayMult + st.addedMult
                        Sound.play("mult_pop")
                    end
                    if st.xMult > 1.0 then
                        anim.displayXMult = anim.displayXMult * st.xMult
                        screenShake = 6
                        Sound.play("xmult_boom")
                        table.insert(anim.floatingTexts, {
                            text = "x" .. st.xMult .. " XMult!",
                            color = UI.COLORS.xmultGold,
                            x = 640,
                            y = 350,
                            alpha = 1.0,
                        })
                    end
                    anim.displayFinalScore = math.floor(anim.displayChips * anim.displayMult * anim.displayXMult)
                    anim.stepCategory = "THẦN BÀI: " .. (st.deity and st.deity.name or "BỔ TRỢ"):upper()
                    anim.stepLog = st.message

                elseif st.type == "final_score" then
                    anim.activeCardIndex = nil
                    Sound.play("xmult_boom")
                    screenShake = 10
                    anim.displayFinalScore = st.finalScore
                    anim.stepCategory = "TỔNG SÁT THƯƠNG"
                    anim.stepLog = anim.displayChips .. " Chips × " .. anim.displayMult .. " Mult" .. (anim.displayXMult > 1.0 and (" × " .. anim.displayXMult .. " XMult") or "") .. " = " .. st.finalScore .. " Sát thương!"

                    local actualDmg, defeated = Monster.takeDamage(game.monster, st.finalScore)
                    anim.damageDealt = actualDmg
                    anim.monsterDefeated = defeated

                    if st.bonusGold and st.bonusGold > 0 then
                        game.gold = game.gold + st.bonusGold
                    end

                    table.insert(anim.floatingTexts, {
                        text = "-" .. actualDmg .. " SÁT THƯƠNG!",
                        color = UI.COLORS.hpRed,
                        x = 160,
                        y = 230,
                        alpha = 1.5,
                    })

                    if defeated then
                        local baseReward = game.monster.isBoss and 15 or (game.monster.isElite and 10 or 4)
                        local unusedHandsBonus = game.handsRemaining * 1
                        local deityBonus = 0
                        for _, d in ipairs(game.deities) do
                            if d.onRoundWin then
                                local r = d.onRoundWin(game)
                                if r and r.addGold then deityBonus = deityBonus + r.addGold end
                            end
                        end
                        anim.earnedGold = baseReward + unusedHandsBonus + deityBonus

                        -- Valoria Passive: +25% Gold on monster defeat
                        if game.selectedFaction == "valoria" or game.selectedSuit == "valoria" then
                            local valBonus = math.max(1, math.floor(anim.earnedGold * 0.25))
                            anim.earnedGold = anim.earnedGold + valBonus
                            table.insert(anim.floatingTexts, {
                                text = "⚔️ Hậu Cần Quân Khí (Valoria): +" .. valBonus .. " Vàng (+25%)!",
                                color = UI.COLORS.goldYellow,
                                x = 640,
                                y = 280,
                                alpha = 2.5,
                            })
                        end

                        -- Elaris Passive: Lộc Biếc Đâm Chồi (Win within half of max hands upgrades a card)
                        if (game.selectedFaction == "elaris" or game.selectedSuit == "elaris") and game.handsRemaining >= math.ceil(game.maxHands / 2) then
                            if game.persistentDeck and #game.persistentDeck > 0 then
                                local targetCard = game.persistentDeck[love.math and love.math.random(#game.persistentDeck) or 1]
                                Deck.upgradeCard(targetCard)
                                table.insert(anim.floatingTexts, {
                                    text = "🌲 Lộc Biếc Đâm Chồi: Tôi luyện thành công lá " .. targetCard.rankName .. targetCard.suitSymbol .. " (+1 Rank)!",
                                    color = { 0.2, 0.85, 0.4, 1 },
                                    x = 640,
                                    y = 330,
                                    alpha = 3.0,
                                })
                            end
                        end

                        -- Increment encounter count for next monster (starts at 10 HP, +50% each encounter indefinitely)
                        game.monsterEncounterCount = (game.monsterEncounterCount or 1) + 1

                        game.gold = game.gold + anim.earnedGold
                        Sound.play("round_win")
                    elseif game.handsRemaining <= 0 then
                        Sound.play("game_over")
                    end
                end
            else
                if anim.stepTimer >= 0.8 or anim.currentStepIndex > #steps + 1 then
                    anim.active = false

                    -- Old card degradation is removed per user request:
                    -- Cards do NOT lose rank on play. Played cards are simply discarded.
                    anim.playedCards = {}

                    -- Check if player has run out of all cards
                    if #game.hand == 0 and #game.deck == 0 and #game.discardPile == 0 then
                        state = "gameover"
                        Sound.play("game_over")
                        return
                    end

                    if anim.monsterDefeated then
                        -- Combat Victory: restore persistent cards back to base ranks
                        if game.persistentDeck then
                            Deck.restoreDeck(game.persistentDeck)
                            game.masterDeck = game.persistentDeck
                            game.deck = {}
                            game.discardPile = {}
                            game.hand = {}
                            clearAllSelections()
                        end

                        if game.monster.isBoss then
                            -- Boss defeated: 2 Deities appear, pick 1 of 2!
                            game.bossDeityDraft = Deities.getBossDraftPool(game.deities, 2)
                            state = "boss_deity"
                            Sound.play("round_win")
                        elseif game.monster.isElite then
                            -- Elite monster defeated: complete node and open bonus treasure chest!
                            if game.currentNodeId and game.map then
                                Map.onNodeCompleted(game.map, game.currentNodeId)
                            end
                            generateBossChestRewards()
                            socketingReturnState = "map"
                            state = "chest"
                            Sound.play("round_win")
                        else
                            -- Normal monster defeated: complete node and return to map!
                            if game.currentNodeId and game.map then
                                Map.onNodeCompleted(game.map, game.currentNodeId)
                            end
                            state = "map"
                            Sound.play("round_win")
                        end
                    elseif game.handsRemaining <= 0 then
                        state = "gameover"
                        Sound.play("game_over")
                    else
                        -- Refill hand while deck has cards (played cards stay in discard pile!)
                        local maxHandSize = (game.selectedFaction == "elaris" or game.selectedSuit == "elaris") and 9 or 8
                        while #game.hand < maxHandSize and #game.deck > 0 do
                            local drawn = table.remove(game.deck)
                            if drawn then
                                drawn.selected = false
                                table.insert(game.hand, drawn)
                            end
                        end

                        -- Deck exhaustion check: all cards played and monster not defeated = Defeat
                        if #game.hand == 0 and #game.deck == 0 and game.monster and game.monster.hp > 0 then
                            state = "gameover"
                            Sound.play("game_over")
                            return
                        end

                        if game.sortMode == "rank" then
                            Deck.sortByRank(game.hand)
                        else
                            Deck.sortBySuit(game.hand)
                        end

                        clearAllSelections()
                        syncCardSelections()
                        state = "playing"
                        Sound.play("card_deal")
                    end
                end
            end
        end
    end
end

--------------------------------------------------------------------------------
-- DRAW FUNCTIONS
--------------------------------------------------------------------------------

local function drawMenu()
    -- Fullscreen felt background
    local winW, winH = love.graphics.getDimensions()
    love.graphics.setColor(UI.COLORS.bg)
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)

    -- Header Title
    love.graphics.setFont(UI.fonts.huge)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf("POKER ROGUELIKE", 0, 35, V_WIDTH, "center")

    love.graphics.setFont(UI.fonts.medium)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.printf("Lựa chọn Phe Phái Khởi Đầu (3 lá ngẫu nhiên - Quái khởi đầu 10 HP, tăng 50% mỗi phòng quái):", 0, 95, V_WIDTH, "center")

    -- 4 Faction Selection Cards
    local factions = {
        {
            id = "aurelia",
            title = "☀️ AURELIA",
            color = Deck.FACTIONS.aurelia.color,
            badge = "Phe Ánh Sáng",
            blessing = "• Hào Quang Thánh Thiện:\nĐòn đánh có thẻ Aurelia nhận x1.15 XMult.\n• Kỷ Luật Thần Thánh:\nBài hình (J, Q, K) cố định điểm, miễn nhiễm suy yếu từ quái vật.",
        },
        {
            id = "elaris",
            title = "🌲 ELARIS",
            color = Deck.FACTIONS.elaris.color,
            badge = "Phe Thiên Nhiên",
            blessing = "• Sức Sống Rừng Già:\nCầm tối đa 9 lá bài & tái chế Chiến Binh (2-10) khi đổi bài.\n• Lộc Biếc Đâm Chồi:\nThắng không quá nửa lượt đánh giúp tôi luyện hoàn hảo 1 lá bài.",
        },
        {
            id = "vharos",
            title = "🔥 VHAROS",
            color = Deck.FACTIONS.vharos.color,
            badge = "Phe Hắc Ám",
            blessing = "• Hơi Thở Ma Quỷ:\nThẻ Vharos khi xuất trận cộng trực tiếp +40 Chips.\n• Huyết Tế Bóng Đêm:\nKhi Chiến Binh (2-10) bị hy sinh, gây sát thương chuẩn bằng số của lá.",
        },
        {
            id = "valoria",
            title = "⚔️ VALORIA",
            color = Deck.FACTIONS.valoria.color,
            badge = "Phe Nhân Loại",
            blessing = "• Chiến Thuật Hành Quân:\nNhận thêm +1 Lượt Đổi Bài miễn phí mỗi trận (4 lượt đổi).\n• Hậu Cần Quân Khí:\nTiêu diệt quái vật tăng +25% vàng thu thập.",
        },
    }

    local cardW = 240
    local cardH = 370
    local startX = (V_WIDTH - (4 * cardW + 3 * 24)) / 2
    local cardY = 140

    local mx, my = toVirtual(love.mouse.getPosition())

    for i, s in ipairs(factions) do
        local cx = startX + (i - 1) * (cardW + 24)
        local isHovered = (mx >= cx and mx <= cx + cardW and my >= cardY and my <= cardY + cardH)

        love.graphics.setColor(0, 0, 0, 0.4)
        UI.drawRoundedRect("fill", cx + 3, cardY + 5, cardW, cardH, 12)

        love.graphics.setColor(isHovered and { 0.16, 0.22, 0.26, 1 } or { 0.12, 0.16, 0.19, 1 })
        UI.drawRoundedRect("fill", cx, cardY, cardW, cardH, 12)

        love.graphics.setLineWidth(isHovered and 3 or 1.5)
        love.graphics.setColor(isHovered and s.color or { 0.35, 0.42, 0.5, 0.8 })
        UI.drawRoundedRect("line", cx, cardY, cardW, cardH, 12)

        love.graphics.setFont(UI.fonts.medium)
        love.graphics.setColor(s.color)
        love.graphics.printf(s.title, cx, cardY + 14, cardW, "center")

        UI.drawSuitSymbol(s.id, cx + cardW / 2, cardY + 70, 52, s.color)

        love.graphics.setColor(s.color[1], s.color[2], s.color[3], 0.25)
        UI.drawRoundedRect("fill", cx + 16, cardY + 110, cardW - 32, 30, 6)
        love.graphics.setFont(UI.fonts.regular)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(s.badge, cx, cardY + 115, cardW, "center")

        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(UI.COLORS.textLight)
        love.graphics.printf(s.blessing, cx + 14, cardY + 150, cardW - 28, "left")

        local btnY = cardY + cardH - 48
        love.graphics.setColor(isHovered and s.color or UI.COLORS.btnNormal)
        UI.drawRoundedRect("fill", cx + 24, btnY, cardW - 48, 36, 6)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(UI.fonts.regular)
        love.graphics.printf("CHỌN PHE NÀY", cx, btnY + 7, cardW, "center")
    end

    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.printf("Mẹo: Nhấn [F11] để Bật/Tắt Full Màn Hình Tràn Viền bất kỳ lúc nào!", 0, V_HEIGHT - 55, V_WIDTH, "center")
    love.graphics.printf("Khởi đầu với 3 lá ngẫu nhiên thuộc phe đã chọn. Đánh bại BOSS để thỉnh Thần Bài Ban Ơn!", 0, V_HEIGHT - 32, V_WIDTH, "center")
end

local function getHandCardPosition(index, totalCards)
    local cardW = 100
    local cardH = 145
    local cardGap = 14
    local handAreaX = 295
    local handAreaW = 820
    local totalHandW = totalCards * cardW + math.max(0, totalCards - 1) * cardGap
    local handStartX = handAreaX + (handAreaW - totalHandW) / 2
    local handStartY = 465
    local cx = handStartX + (index - 1) * (cardW + cardGap)
    return cx, handStartY, cardW, cardH
end

local function drawPlayingState()
    syncCardSelections()
    local winW, winH = love.graphics.getDimensions()
    love.graphics.setColor(UI.COLORS.felt)
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)

    local mx, my = toVirtual(love.mouse.getPosition())
    hoveredDeityTooltip = nil
    hoveredCardTooltip = nil
    buttons = {}

    local m = game.monster
    local isBoss = m and m.isBoss
    local isElite = m and m.isElite

    ----------------------------------------------------------------------------
    -- 1. LEFT SIDEBAR (Balatro Layout: Width 265, Height 690)
    ----------------------------------------------------------------------------
    local panelX = 15
    local panelY = 15
    local panelW = 265
    local panelH = 690

    love.graphics.setColor(UI.COLORS.panelBg)
    UI.drawRoundedRect("fill", panelX, panelY, panelW, panelH, 8)
    love.graphics.setColor(UI.COLORS.panelBorder)
    UI.drawRoundedRect("line", panelX, panelY, panelW, panelH, 8)

    -- A. Monster / Blind Box (Top)
    local mbX = panelX + 10
    local mbY = panelY + 10
    local mbW = panelW - 20
    local mbH = 175

    love.graphics.setColor(0.10, 0.13, 0.16, 0.95)
    UI.drawRoundedRect("fill", mbX, mbY, mbW, mbH, 6)
    love.graphics.setColor(0.24, 0.32, 0.40, 1)
    UI.drawRoundedRect("line", mbX, mbY, mbW, mbH, 6)

    -- Monster Banner Header
    local bannerColor = isBoss and { 0.85, 0.22, 0.25, 1 } or (isElite and { 0.88, 0.55, 0.15, 1 } or { 0.90, 0.45, 0.15, 1 })
    local bannerText = isBoss and "BOSS BLIND" or (isElite and "ELITE BLIND" or "SMALL BLIND")
    love.graphics.setColor(bannerColor)
    UI.drawRoundedRect("fill", mbX, mbY, mbW, 30, 6)
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(bannerText .. ": " .. (m and m.name or "Quái"), mbX, mbY + 6, mbW, "center")

    -- Monster Emblem / Badge
    local emblemCX = mbX + 36
    local emblemCY = mbY + 66
    local emblemR = 22
    love.graphics.setColor(0.16, 0.20, 0.25, 1)
    love.graphics.circle("fill", emblemCX, emblemCY, emblemR)
    love.graphics.setColor(bannerColor)
    love.graphics.circle("line", emblemCX, emblemCY, emblemR)
    UI.drawSuitSymbol(game.selectedSuit, emblemCX, emblemCY, 24, bannerColor)

    -- Target HP info right of emblem
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.print("Đạt ít nhất:", mbX + 68, mbY + 44)

    love.graphics.setFont(UI.fonts.large)
    love.graphics.setColor(isBoss and UI.COLORS.hpRed or UI.COLORS.goldYellow)
    love.graphics.print(m and (m.hp .. " HP") or "0 HP", mbX + 68, mbY + 58)

    -- Reward text
    local baseReward = (m and m.isBoss) and 15 or ((m and m.isElite) and 10 or 4)
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(UI.COLORS.goldYellow)
    local rewStr = "Thưởng: " .. string.rep("$", math.min(5, baseReward)) .. " ($" .. baseReward .. ")"
    love.graphics.printf(rewStr, mbX, mbY + 102, mbW, "center")

    -- HP Bar
    if m then
        UI.drawMonsterHpBar(mbX + 10, mbY + 124, mbW - 20, 20, m.hp, m.maxHp, m.damageLagHp)
    end

    -- Trait / Desc line
    if m and m.desc and m.desc ~= "" then
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(UI.COLORS.textMuted)
        love.graphics.printf(m.desc, mbX + 6, mbY + 148, mbW - 12, "center")
    end

    -- B. Score Box ("Điểm Ván" / Round Score)
    local sbX = panelX + 10
    local sbY = panelY + 195
    local sbW = panelW - 20
    local sbH = 145

    love.graphics.setColor(0.10, 0.13, 0.16, 0.95)
    UI.drawRoundedRect("fill", sbX, sbY, sbW, sbH, 6)
    love.graphics.setColor(0.24, 0.32, 0.40, 1)
    UI.drawRoundedRect("line", sbX, sbY, sbW, sbH, 6)

    love.graphics.setFont(UI.fonts.regular)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.printf("Điểm Ván", sbX, sbY + 8, sbW, "center")

    -- Check selected hand
    local selectedCards = getSelectedCards()
    local eval = (#selectedCards > 0) and Poker.evaluate(selectedCards, game.unlockedHands) or nil
    local scPreview = eval and Scoring.calculate(eval, game.deities, {
        handsRemaining = game.handsRemaining,
        round = game.round,
        monster = game.monster,
        discardBuffs = game.discardBuffs,
        selectedSuit = game.selectedSuit,
    }) or nil

    if eval and scPreview then
        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(UI.COLORS.goldYellow)
        love.graphics.printf(eval.type.vnName, sbX, sbY + 30, sbW, "center")

        -- Chips box (Blue)
        local cbX = sbX + 12
        local cbY = sbY + 54
        local cbW = 96
        local cbH = 50
        love.graphics.setColor(0.12, 0.32, 0.65, 0.95)
        UI.drawRoundedRect("fill", cbX, cbY, cbW, cbH, 6)
        love.graphics.setColor(UI.COLORS.chipsBlue)
        UI.drawRoundedRect("line", cbX, cbY, cbW, cbH, 6)
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.printf("Chips", cbX, cbY + 4, cbW, "center")
        love.graphics.setFont(UI.fonts.large)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(tostring(scPreview.totalChips), cbX, cbY + 16, cbW, "center")

        -- Multiplication X
        love.graphics.setFont(UI.fonts.large)
        love.graphics.setColor(UI.COLORS.multRed)
        love.graphics.printf("X", sbX + 108, cbY + 12, 28, "center")

        -- Mult box (Red)
        local mbX2 = sbX + 137
        local mbY2 = cbY
        local mbW2 = 96
        local mbH2 = 50
        love.graphics.setColor(0.65, 0.18, 0.22, 0.95)
        UI.drawRoundedRect("fill", mbX2, mbY2, mbW2, mbH2, 6)
        love.graphics.setColor(UI.COLORS.multRed)
        UI.drawRoundedRect("line", mbX2, mbY2, mbW2, mbH2, 6)
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.printf("Mult", mbX2, mbY2 + 4, mbW2, "center")
        love.graphics.setFont(UI.fonts.large)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(tostring(scPreview.totalMult), mbX2, mbY2 + 16, mbW2, "center")

        -- Damage projection
        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(UI.COLORS.hpRed)
        love.graphics.printf("Dự kiến: " .. scPreview.finalScore .. " HP", sbX, sbY + 108, sbW, "center")
    else
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(UI.COLORS.textMuted)
        love.graphics.printf("Chọn bài để tính điểm", sbX, sbY + 30, sbW, "center")

        -- Chips box 0
        local cbX = sbX + 12
        local cbY = sbY + 54
        local cbW = 96
        local cbH = 50
        love.graphics.setColor(0.12, 0.22, 0.35, 0.6)
        UI.drawRoundedRect("fill", cbX, cbY, cbW, cbH, 6)
        love.graphics.setColor(UI.COLORS.chipsBlue[1], UI.COLORS.chipsBlue[2], UI.COLORS.chipsBlue[3], 0.4)
        UI.drawRoundedRect("line", cbX, cbY, cbW, cbH, 6)
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(UI.COLORS.textMuted)
        love.graphics.printf("Chips", cbX, cbY + 4, cbW, "center")
        love.graphics.setFont(UI.fonts.large)
        love.graphics.setColor(UI.COLORS.textMuted)
        love.graphics.printf("0", cbX, cbY + 16, cbW, "center")

        -- X
        love.graphics.setFont(UI.fonts.large)
        love.graphics.setColor(0.5, 0.5, 0.5, 0.6)
        love.graphics.printf("X", sbX + 108, cbY + 12, 28, "center")

        -- Mult box 0
        local mbX2 = sbX + 137
        local mbY2 = cbY
        local mbW2 = 96
        local mbH2 = 50
        love.graphics.setColor(0.28, 0.14, 0.16, 0.6)
        UI.drawRoundedRect("fill", mbX2, mbY2, mbW2, mbH2, 6)
        love.graphics.setColor(UI.COLORS.multRed[1], UI.COLORS.multRed[2], UI.COLORS.multRed[3], 0.4)
        UI.drawRoundedRect("line", mbX2, mbY2, mbW2, mbH2, 6)
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(UI.COLORS.textMuted)
        love.graphics.printf("Mult", mbX2, mbY2 + 4, mbW2, "center")
        love.graphics.setFont(UI.fonts.large)
        love.graphics.setColor(UI.COLORS.textMuted)
        love.graphics.printf("0", mbX2, mbY2 + 16, mbW2, "center")

        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(UI.COLORS.textMuted)
        love.graphics.printf("Dự kiến: 0 HP", sbX, sbY + 108, sbW, "center")
    end

    -- Discard Buff Indicator Pill in Score Box
    local db = game.discardBuffs
    if db and (db.chips > 0 or db.mult > 0 or (db.xMult and db.xMult > 1.0) or (db.bonusDamagePct and db.bonusDamagePct > 0)) then
        local parts = {}
        if db.chips > 0 then table.insert(parts, "+" .. db.chips .. "c") end
        if db.mult > 0 then table.insert(parts, "+" .. db.mult .. "m") end
        if db.xMult and db.xMult > 1.0 then table.insert(parts, "x" .. string.format("%.2f", db.xMult)) end
        if db.bonusDamagePct and db.bonusDamagePct > 0 then table.insert(parts, "+" .. math.floor(db.bonusDamagePct * 100) .. "%") end

        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(UI.COLORS.goldYellow)
        love.graphics.printf("⚡ Buff Bỏ Bài: " .. table.concat(parts, " | "), sbX, sbY + 126, sbW, "center")
    end

    -- C. Sidebar Action Buttons
    local btnHandbookPlay = {
        id = "open_handbook",
        text = "T.tin Trận Này [H]",
        x = panelX + 10,
        y = panelY + 350,
        w = panelW - 20,
        h = 42,
        color = { 0.82, 0.26, 0.24, 1 },
        font = UI.fonts.small,
    }
    table.insert(buttons, btnHandbookPlay)
    UI.drawButton(btnHandbookPlay, mx >= btnHandbookPlay.x and mx <= btnHandbookPlay.x + btnHandbookPlay.w and my >= btnHandbookPlay.y and my <= btnHandbookPlay.y + btnHandbookPlay.h)

    local btnDeckPlay = {
        id = "open_deck_viewer",
        text = "Tuỳ Chọn [Tab]",
        x = panelX + 10,
        y = panelY + 400,
        w = panelW - 20,
        h = 42,
        color = { 0.88, 0.52, 0.18, 1 },
        font = UI.fonts.small,
    }
    table.insert(buttons, btnDeckPlay)
    UI.drawButton(btnDeckPlay, mx >= btnDeckPlay.x and mx <= btnDeckPlay.x + btnDeckPlay.w and my >= btnDeckPlay.y and my <= btnDeckPlay.y + btnDeckPlay.h)

    -- D. Stats Matrix (Bottom)
    local matrixY = panelY + 452

    -- Hands Remaining (Blue Box)
    local handBoxW = 118
    local handBoxH = 65
    love.graphics.setColor(0.12, 0.28, 0.55, 0.95)
    UI.drawRoundedRect("fill", panelX + 10, matrixY, handBoxW, handBoxH, 6)
    love.graphics.setColor(UI.COLORS.chipsBlue)
    UI.drawRoundedRect("line", panelX + 10, matrixY, handBoxW, handBoxH, 6)
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(0.85, 0.92, 1.0, 1)
    love.graphics.printf("Tay Bài", panelX + 10, matrixY + 6, handBoxW, "center")
    love.graphics.setFont(UI.fonts.large)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(tostring(game.handsRemaining), panelX + 10, matrixY + 22, handBoxW, "center")

    -- Discards Remaining (Red Box)
    local discBoxY = matrixY + 73
    love.graphics.setColor(0.55, 0.18, 0.20, 0.95)
    UI.drawRoundedRect("fill", panelX + 10, discBoxY, handBoxW, handBoxH, 6)
    love.graphics.setColor(UI.COLORS.multRed)
    UI.drawRoundedRect("line", panelX + 10, discBoxY, handBoxW, handBoxH, 6)
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(1.0, 0.85, 0.85, 1)
    love.graphics.printf("Lượt Bỏ", panelX + 10, discBoxY + 6, handBoxW, "center")
    love.graphics.setFont(UI.fonts.large)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(tostring(game.discardsRemaining), panelX + 10, discBoxY + 22, handBoxW, "center")

    -- Gold Cash Box (Right Box)
    local goldBoxX = panelX + 136
    local goldBoxW = panelW - 146
    local goldBoxH = 138
    love.graphics.setColor(0.12, 0.15, 0.18, 0.95)
    UI.drawRoundedRect("fill", goldBoxX, matrixY, goldBoxW, goldBoxH, 6)
    love.graphics.setColor(UI.COLORS.goldYellow[1], UI.COLORS.goldYellow[2], UI.COLORS.goldYellow[3], 0.8)
    UI.drawRoundedRect("line", goldBoxX, matrixY, goldBoxW, goldBoxH, 6)
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf("Tiền Vàng", goldBoxX, matrixY + 12, goldBoxW, "center")
    love.graphics.setFont(UI.fonts.huge)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf("$" .. game.gold, goldBoxX, matrixY + 48, goldBoxW, "center")

    -- Ante & Round Info (Footer)
    local footerY = matrixY + 146
    local footerH = 82
    love.graphics.setColor(0.10, 0.13, 0.16, 0.95)
    UI.drawRoundedRect("fill", panelX + 10, footerY, panelW - 20, footerH, 6)
    love.graphics.setColor(0.24, 0.32, 0.40, 1)
    UI.drawRoundedRect("line", panelX + 10, footerY, panelW - 20, footerH, 6)

    -- Divider
    love.graphics.line(panelX + 10 + (panelW - 20) / 2, footerY + 6, panelX + 10 + (panelW - 20) / 2, footerY + footerH - 6)

    -- Left: Ante
    local halfW = (panelW - 20) / 2
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.printf("Ante", panelX + 10, footerY + 12, halfW, "center")
    love.graphics.setFont(UI.fonts.medium)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf((game.map and game.map.currentFloor or 1) .. "/20", panelX + 10, footerY + 38, halfW, "center")

    -- Right: Round (Ván)
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.printf("Ván", panelX + 10 + halfW, footerY + 12, halfW, "center")
    love.graphics.setFont(UI.fonts.medium)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(tostring(game.round), panelX + 10 + halfW, footerY + 38, halfW, "center")

    ----------------------------------------------------------------------------
    -- 2. TOP BAR: DEITIES (0/5) & CONSUMABLES (0/2)
    ----------------------------------------------------------------------------
    local topStartX = 295
    local topStartY = 15

    -- Deities Section
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.print("THẦN HỘ MỆNH (" .. #game.deities .. "/5)", topStartX + 4, topStartY)

    local deitySlotW = 112
    local deitySlotH = 88
    local deityGap = 12
    local deityY = topStartY + 22

    for i = 1, 5 do
        local dx = topStartX + (i - 1) * (deitySlotW + deityGap)
        local d = game.deities[i]

        if d then
            local isHovered = (mx >= dx and mx <= dx + deitySlotW and my >= deityY and my <= deityY + deitySlotH)
            if isHovered then hoveredDeityTooltip = d end

            local borderCol = { 0.35, 0.45, 0.55, 1 }
            if d.rarity == "uncommon" then borderCol = { 0.2, 0.8, 0.4, 1 }
            elseif d.rarity == "rare" then borderCol = { 0.2, 0.6, 1.0, 1 }
            elseif d.rarity == "legendary" then borderCol = { 0.95, 0.75, 0.1, 1 }
            end

            love.graphics.setColor(0.18, 0.22, 0.26, 1)
            UI.drawRoundedRect("fill", dx, deityY, deitySlotW, deitySlotH, 6)
            love.graphics.setLineWidth(1.5)
            love.graphics.setColor(borderCol)
            UI.drawRoundedRect("line", dx, deityY, deitySlotW, deitySlotH, 6)

            love.graphics.setFont(UI.fonts.small)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf(d.name, dx + 4, deityY + 8, deitySlotW - 8, "center")

            love.graphics.setFont(UI.fonts.tiny)
            love.graphics.setColor(UI.COLORS.textMuted)
            love.graphics.printf(d.desc, dx + 6, deityY + 34, deitySlotW - 12, "center")
        else
            love.graphics.setColor(0.12, 0.15, 0.18, 0.6)
            UI.drawRoundedRect("fill", dx, deityY, deitySlotW, deitySlotH, 6)
            love.graphics.setLineWidth(1)
            love.graphics.setColor(0.28, 0.34, 0.40, 0.6)
            UI.drawRoundedRect("line", dx, deityY, deitySlotW, deitySlotH, 6)
            love.graphics.setFont(UI.fonts.large)
            love.graphics.setColor(0.35, 0.42, 0.48, 0.6)
            love.graphics.printf("+", dx, deityY + 24, deitySlotW, "center")
        end
    end

    -- Consumables Section (0/2)
    local conStartX = topStartX + 5 * (deitySlotW + deityGap) + 20
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.print("TIÊU HAO (0/2)", conStartX + 4, topStartY)

    local conSlotW = 86
    local conSlotH = 88
    local conGap = 12
    for j = 1, 2 do
        local cx = conStartX + (j - 1) * (conSlotW + conGap)
        love.graphics.setColor(0.12, 0.15, 0.18, 0.6)
        UI.drawRoundedRect("fill", cx, deityY, conSlotW, conSlotH, 6)
        love.graphics.setLineWidth(1)
        love.graphics.setColor(0.28, 0.34, 0.40, 0.5)
        UI.drawRoundedRect("line", cx, deityY, conSlotW, conSlotH, 6)
        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(0.35, 0.42, 0.48, 0.5)
        love.graphics.printf("Trống", cx, deityY + 34, conSlotW, "center")
    end

    ----------------------------------------------------------------------------
    -- 3. CENTER FELT TABLE: PLAYED / SELECTED HINTS
    ----------------------------------------------------------------------------
    if eval and scPreview then
        -- Subtle highlight banner above player cards
        local hbW = 540
        local hbH = 34
        local hbX = 295 + (820 - hbW) / 2
        local hbY = 412
        love.graphics.setColor(0.10, 0.14, 0.18, 0.85)
        UI.drawRoundedRect("fill", hbX, hbY, hbW, hbH, 6)
        love.graphics.setColor(UI.COLORS.goldYellow[1], UI.COLORS.goldYellow[2], UI.COLORS.goldYellow[3], 0.7)
        UI.drawRoundedRect("line", hbX, hbY, hbW, hbH, 6)

        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(UI.COLORS.goldYellow)
        love.graphics.printf(eval.type.vnName .. ": " .. scPreview.totalChips .. " Chips × " .. scPreview.totalMult .. " Mult = " .. scPreview.finalScore .. " Sát Thương!", hbX, hbY + 8, hbW, "center")
    else
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(0.85, 0.90, 0.95, 0.75)
        love.graphics.printf("[Chuột trái]: Chọn 1-5 lá bài | [Chuột phải]: Xem chi tiết & độ bền | [F11]: Toàn màn hình", 295, 420, 820, "center")
    end

    ----------------------------------------------------------------------------
    -- 4. PLAYER HAND CARDS
    ----------------------------------------------------------------------------
    for i, c in ipairs(game.hand) do
        local cx, cy, cardW, cardH = getHandCardPosition(i, #game.hand)
        if c.selected then cy = cy - 26 end

        local isHovered = (mx >= cx and mx <= cx + cardW and my >= cy and my <= cy + cardH)
        c.hovered = isHovered
        if isHovered and c.equipments and #c.equipments > 0 then
            hoveredCardTooltip = c
        end

        UI.drawCard(c, cx, cy, cardW, cardH)
    end

    -- Hand count badge (e.g. 8/8) above action buttons
    local maxHandSize = (game.selectedFaction == "elaris" or game.selectedSuit == "elaris") and 9 or 8
    local handCountText = #game.hand .. "/" .. maxHandSize
    local hcW = 60
    local hcH = 22
    local hcX = 705 - hcW / 2
    local hcY = 608
    love.graphics.setColor(0.12, 0.16, 0.20, 0.9)
    UI.drawRoundedRect("fill", hcX, hcY, hcW, hcH, 4)
    love.graphics.setColor(0.35, 0.45, 0.55, 0.8)
    UI.drawRoundedRect("line", hcX, hcY, hcW, hcH, 4)
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf(handCountText, hcX, hcY + 3, hcW, "center")

    ----------------------------------------------------------------------------
    -- 5. BALATRO ACTION BUTTONS ROW
    ----------------------------------------------------------------------------
    local hasSelection = (#selectedCards >= 1 and #selectedCards <= 5)
    local actionY = 636

    -- Left: Chơi Tay Bài [Space]
    local btnPlay = {
        id = "play",
        text = "Chơi Tay Bài [Space]",
        x = 445,
        y = actionY,
        w = 175,
        h = 58,
        color = UI.COLORS.chipsBlue,
        font = UI.fonts.small,
        disabled = not hasSelection or game.handsRemaining <= 0,
    }
    table.insert(buttons, btnPlay)
    UI.drawButton(btnPlay, mx >= btnPlay.x and mx <= btnPlay.x + btnPlay.w and my >= btnPlay.y and my <= btnPlay.y + btnPlay.h)

    -- Center: Sắp Xếp Container Box
    local sortBoxX = 635
    local sortBoxY = actionY - 8
    local sortBoxW = 145
    local sortBoxH = 68
    love.graphics.setColor(0.12, 0.16, 0.20, 0.95)
    UI.drawRoundedRect("fill", sortBoxX, sortBoxY, sortBoxW, sortBoxH, 6)
    love.graphics.setColor(0.30, 0.38, 0.46, 1)
    UI.drawRoundedRect("line", sortBoxX, sortBoxY, sortBoxW, sortBoxH, 6)

    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.printf("SẮP XẾP BÀI", sortBoxX, sortBoxY + 4, sortBoxW, "center")

    local btnSortRank = {
        id = "sort_rank",
        text = "Bậc [R]",
        x = sortBoxX + 6,
        y = sortBoxY + 24,
        w = 62,
        h = 36,
        color = (game.sortMode == "rank") and { 0.28, 0.48, 0.72, 1 } or UI.COLORS.btnNormal,
        font = UI.fonts.tiny,
    }
    table.insert(buttons, btnSortRank)
    UI.drawButton(btnSortRank, mx >= btnSortRank.x and mx <= btnSortRank.x + btnSortRank.w and my >= btnSortRank.y and my <= btnSortRank.y + btnSortRank.h)

    local btnSortSuit = {
        id = "sort_suit",
        text = "Chất [S]",
        x = sortBoxX + 76,
        y = sortBoxY + 24,
        w = 62,
        h = 36,
        color = (game.sortMode == "suit") and { 0.28, 0.48, 0.72, 1 } or UI.COLORS.btnNormal,
        font = UI.fonts.tiny,
    }
    table.insert(buttons, btnSortSuit)
    UI.drawButton(btnSortSuit, mx >= btnSortSuit.x and mx <= btnSortSuit.x + btnSortSuit.w and my >= btnSortSuit.y and my <= btnSortSuit.y + btnSortSuit.h)

    -- Right: Bỏ Bài [D]
    local btnDiscard = {
        id = "discard",
        text = "Bỏ Bài [D]",
        x = 795,
        y = actionY,
        w = 160,
        h = 58,
        color = UI.COLORS.multRed,
        font = UI.fonts.small,
        disabled = not hasSelection or game.discardsRemaining <= 0,
    }
    table.insert(buttons, btnDiscard)
    UI.drawButton(btnDiscard, mx >= btnDiscard.x and mx <= btnDiscard.x + btnDiscard.w and my >= btnDiscard.y and my <= btnDiscard.y + btnDiscard.h)

    ----------------------------------------------------------------------------
    -- 6. BOTTOM-RIGHT FACEDOWN DRAW DECK PILE
    ----------------------------------------------------------------------------
    local deckPileX = 1140
    local deckPileY = 535
    local deckPileW = 115
    local deckPileH = 160

    local isDeckHovered = (mx >= deckPileX and mx <= deckPileX + deckPileW and my >= deckPileY and my <= deckPileY + deckPileH)

    -- Layer 1 & 2 shadow stack
    love.graphics.setColor(0.08, 0.10, 0.12, 0.7)
    UI.drawRoundedRect("fill", deckPileX - 4, deckPileY + 4, deckPileW, deckPileH, 8)
    UI.drawRoundedRect("fill", deckPileX - 2, deckPileY + 2, deckPileW, deckPileH, 8)

    -- Top Deck Card Back
    love.graphics.setColor(isDeckHovered and { 0.22, 0.32, 0.42, 1 } or { 0.16, 0.20, 0.26, 1 })
    UI.drawRoundedRect("fill", deckPileX, deckPileY, deckPileW, deckPileH, 8)
    love.graphics.setLineWidth(isDeckHovered and 2.5 or 1.5)
    love.graphics.setColor(isDeckHovered and UI.COLORS.goldYellow or { 0.35, 0.45, 0.55, 1 })
    UI.drawRoundedRect("line", deckPileX, deckPileY, deckPileW, deckPileH, 8)

    -- Card back pattern: inner decorative border & crest
    love.graphics.setColor(0.24, 0.32, 0.40, 0.7)
    UI.drawRoundedRect("line", deckPileX + 6, deckPileY + 6, deckPileW - 12, deckPileH - 12, 6)

    -- Faction symbol on card back
    UI.drawSuitSymbol(game.selectedSuit, deckPileX + deckPileW / 2, deckPileY + deckPileH / 2 - 10, 36)

    -- Deck Pile Label & Counter
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf("BỘ BÀI [Tab]", deckPileX, deckPileY + 12, deckPileW, "center")

    local totalCardsInGame = #game.deck + #game.discardPile + #game.hand
    local deckCountStr = #game.deck .. " / " .. totalCardsInGame
    love.graphics.setFont(UI.fonts.medium)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(deckCountStr, deckPileX, deckPileY + deckPileH - 34, deckPileW, "center")

    local btnDeckPile = {
        id = "open_deck_viewer",
        x = deckPileX,
        y = deckPileY,
        w = deckPileW,
        h = deckPileH,
    }
    table.insert(buttons, btnDeckPile)

    ----------------------------------------------------------------------------
    -- 7. TOOLTIPS (Deity & Card Equipment)
    ----------------------------------------------------------------------------
    if hoveredDeityTooltip then
        local d = hoveredDeityTooltip
        local ttW = 290
        local ttH = 95
        local ttx = math.min(V_WIDTH - ttW - 10, math.max(10, mx + 12))
        local tty = my + 18

        love.graphics.setColor(0.08, 0.10, 0.12, 0.95)
        UI.drawRoundedRect("fill", ttx, tty, ttW, ttH, 6)
        love.graphics.setColor(UI.COLORS.goldYellow)
        UI.drawRoundedRect("line", ttx, tty, ttW, ttH, 6)

        love.graphics.setFont(UI.fonts.regular)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(d.name .. " (" .. d.rarity:upper() .. ")", ttx + 10, tty + 8)

        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(UI.COLORS.textLight)
        love.graphics.printf(d.desc, ttx + 10, tty + 34, ttW - 20, "left")
    end

    if hoveredCardTooltip then
        local c = hoveredCardTooltip
        local ttW = 280
        local ttH = 30 + #c.equipments * 26
        local ttx = math.min(V_WIDTH - ttW - 10, math.max(10, mx + 12))
        local tty = math.max(10, my - ttH - 10)

        love.graphics.setColor(0.08, 0.10, 0.12, 0.96)
        UI.drawRoundedRect("fill", ttx, tty, ttW, ttH, 6)
        love.graphics.setColor(UI.COLORS.chipsBlue)
        UI.drawRoundedRect("line", ttx, tty, ttW, ttH, 6)

        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(UI.COLORS.goldYellow)
        love.graphics.print("Trang bị trên lá (" .. #c.equipments .. "/5 ô):", ttx + 10, tty + 6)

        for s, eq in ipairs(c.equipments) do
            love.graphics.setColor(eq.color or UI.COLORS.textLight)
            love.graphics.setFont(UI.fonts.tiny)
            love.graphics.print("• " .. eq.name .. ": " .. eq.desc, ttx + 12, tty + 14 + s * 22)
        end
    end
end

local function drawScoringState()
    drawPlayingState()

    love.graphics.setColor(0, 0, 0, 0.70)
    love.graphics.rectangle("fill", 0, 0, V_WIDTH, V_HEIGHT)

    local bannerW = 980
    local bannerH = 470
    local bannerX = (V_WIDTH - bannerW) / 2
    local bannerY = 115

    -- Modal panel background & border
    love.graphics.setColor(UI.COLORS.panelBg)
    UI.drawRoundedRect("fill", bannerX, bannerY, bannerW, bannerH, 14)
    love.graphics.setLineWidth(3)
    love.graphics.setColor(UI.COLORS.goldYellow)
    UI.drawRoundedRect("line", bannerX, bannerY, bannerW, bannerH, 14)

    -- 1. Modal Header: Hand Type & description
    love.graphics.setFont(UI.fonts.large)
    love.graphics.setColor(UI.COLORS.goldYellow)
    local handNameText = anim.evalResult.type.vnName .. " (" .. anim.evalResult.type.name .. ")"
    love.graphics.printf(handNameText, bannerX, bannerY + 14, bannerW, "center")

    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.printf("ĐANG GIẢI MÃ VÀ CỘNG DỒN TỪNG LÁ BÀI & THẦN BÀI / TRANG BỊ", bannerX, bannerY + 44, bannerW, "center")

    -- 2. Played Cards Row
    local cards = anim.playedCards
    local cardW = 90
    local cardH = 130
    local cardGap = 16
    local totalCardsW = #cards * cardW + (#cards - 1) * cardGap
    local startCX = bannerX + (bannerW - totalCardsW) / 2
    local baseCardY = bannerY + 72

    for i, c in ipairs(cards) do
        local cx = startCX + (i - 1) * (cardW + cardGap)
        local cy = baseCardY
        local isActive = (anim.activeCardIndex == i)
        local isScored = (anim.scoredCards and anim.scoredCards[i] ~= nil)

        if isActive then
            cy = baseCardY - 18 -- Lift active card
        end

        -- Dim cards not yet scored
        if not isActive and not isScored and anim.currentStepIndex <= #anim.scoringData.steps then
            love.graphics.setColor(1, 1, 1, 0.65)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end

        UI.drawCard(c, cx, cy, cardW, cardH)

        -- If actively scoring: Draw golden highlight ring and floating pill above
        if isActive then
            love.graphics.setLineWidth(3)
            love.graphics.setColor(UI.COLORS.goldYellow)
            UI.drawRoundedRect("line", cx - 2, cy - 2, cardW + 4, cardH + 4, 8)

            -- Floating pill above card
            local pillW = 104
            local pillH = 26
            local pillX = cx + (cardW - pillW) / 2
            local pillY = cy - 32

            love.graphics.setColor(0.12, 0.16, 0.22, 0.95)
            UI.drawRoundedRect("fill", pillX, pillY, pillW, pillH, 6)
            love.graphics.setColor(UI.COLORS.goldYellow)
            UI.drawRoundedRect("line", pillX, pillY, pillW, pillH, 6)

            love.graphics.setFont(UI.fonts.small)
            love.graphics.setColor(UI.COLORS.goldYellow)
            local bonusText = "+" .. c.baseChips .. " Chips"
            if anim.scoredCards and anim.scoredCards[i] then
                local sc = anim.scoredCards[i]
                if sc.addedMult and sc.addedMult > 0 then
                    bonusText = "+" .. sc.addedChips .. "c/+" .. sc.addedMult .. "m"
                else
                    bonusText = "+" .. sc.addedChips .. " Chips"
                end
            end
            love.graphics.printf(bonusText, pillX, pillY + 4, pillW, "center")

        elseif isScored then
            -- Small green check badge below scored card
            local badgeW = 76
            local badgeH = 20
            local badgeX = cx + (cardW - badgeW) / 2
            local badgeY = cy + cardH + 4

            love.graphics.setColor(0.10, 0.25, 0.16, 0.90)
            UI.drawRoundedRect("fill", badgeX, badgeY, badgeW, badgeH, 4)
            love.graphics.setColor(UI.COLORS.hpGreen)
            UI.drawRoundedRect("line", badgeX, badgeY, badgeW, badgeH, 4)

            love.graphics.setFont(UI.fonts.tiny)
            love.graphics.setColor(UI.COLORS.hpGreen)
            local scoredInfo = anim.scoredCards[i]
            love.graphics.printf("✓ +" .. scoredInfo.addedChips .. "c", badgeX, badgeY + 2, badgeW, "center")
        end
    end

    -- 3. Dedicated Event / Step Explanation Banner
    local logBarW = bannerW - 60
    local logBarH = 38
    local logBarX = bannerX + 30
    local logBarY = bannerY + 236

    love.graphics.setColor(0.08, 0.10, 0.14, 0.92)
    UI.drawRoundedRect("fill", logBarX, logBarY, logBarW, logBarH, 6)
    love.graphics.setLineWidth(1.5)
    love.graphics.setColor(0.30, 0.38, 0.48, 0.8)
    UI.drawRoundedRect("line", logBarX, logBarY, logBarW, logBarH, 6)

    -- Step Category Pill on the left
    local catPillW = 150
    local catPillH = 28
    local catPillX = logBarX + 6
    local catPillY = logBarY + 5

    local catColor = UI.COLORS.chipsBlue
    local catName = anim.stepCategory or "TAY BÀI GỐC"
    if catName:find("LÁ BÀI") then
        catColor = UI.COLORS.goldYellow
    elseif catName:find("TRANG BỊ") then
        catColor = { 0.75, 0.35, 0.95, 1 }
    elseif catName:find("THẦN BÀI") then
        catColor = UI.COLORS.xmultGold
    elseif catName:find("SÁT THƯƠNG") then
        catColor = UI.COLORS.hpRed
    end

    love.graphics.setColor(catColor[1], catColor[2], catColor[3], 0.25)
    UI.drawRoundedRect("fill", catPillX, catPillY, catPillW, catPillH, 4)
    love.graphics.setColor(catColor)
    UI.drawRoundedRect("line", catPillX, catPillY, catPillW, catPillH, 4)

    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(catColor)
    love.graphics.printf(catName, catPillX, catPillY + 4, catPillW, "center")

    -- Step Explanation Text
    love.graphics.setFont(UI.fonts.regular)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.printf(anim.stepLog or "", logBarX + catPillW + 16, logBarY + 8, logBarW - catPillW - 24, "left")

    -- 4. Four Formula Calculation Boxes:
    -- [ TỔNG CHIPS ]  ×  [ TỔNG MULT ]  ×  [ HỆ SỐ XMULT ]  =  [ SÁT THƯƠNG (HP) ]
    local boxW = 180
    local boxH = 74
    local opW = 34
    local totalRowW = 4 * boxW + 3 * opW
    local startRowX = bannerX + (bannerW - totalRowW) / 2
    local rowY = bannerY + 288

    -- Box 1: TỔNG CHIPS
    local b1X = startRowX
    love.graphics.setColor(UI.COLORS.chipsBlue[1], UI.COLORS.chipsBlue[2], UI.COLORS.chipsBlue[3], 0.22)
    UI.drawRoundedRect("fill", b1X, rowY, boxW, boxH, 8)
    love.graphics.setLineWidth(2)
    love.graphics.setColor(UI.COLORS.chipsBlue)
    UI.drawRoundedRect("line", b1X, rowY, boxW, boxH, 8)
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.printf("TỔNG CHIPS", b1X, rowY + 8, boxW, "center")
    love.graphics.setFont(UI.fonts.huge)
    love.graphics.setColor(UI.COLORS.chipsBlue)
    love.graphics.printf(tostring(anim.displayChips), b1X, rowY + 22, boxW, "center")

    -- Operator 1: ×
    local op1X = b1X + boxW
    love.graphics.setFont(UI.fonts.large)
    love.graphics.setColor(1, 1, 1, 0.75)
    love.graphics.printf("×", op1X, rowY + 22, opW, "center")

    -- Box 2: TỔNG MULT
    local b2X = op1X + opW
    love.graphics.setColor(UI.COLORS.multRed[1], UI.COLORS.multRed[2], UI.COLORS.multRed[3], 0.22)
    UI.drawRoundedRect("fill", b2X, rowY, boxW, boxH, 8)
    love.graphics.setColor(UI.COLORS.multRed)
    UI.drawRoundedRect("line", b2X, rowY, boxW, boxH, 8)
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.printf("TỔNG MULT", b2X, rowY + 8, boxW, "center")
    love.graphics.setFont(UI.fonts.huge)
    love.graphics.setColor(UI.COLORS.multRed)
    love.graphics.printf(tostring(anim.displayMult), b2X, rowY + 22, boxW, "center")

    -- Operator 2: ×
    local op2X = b2X + boxW
    love.graphics.setFont(UI.fonts.large)
    love.graphics.setColor(1, 1, 1, 0.75)
    love.graphics.printf("×", op2X, rowY + 22, opW, "center")

    -- Box 3: HỆ SỐ XMULT
    local b3X = op2X + opW
    local xmultActive = anim.displayXMult > 1.0
    love.graphics.setColor(UI.COLORS.xmultGold[1], UI.COLORS.xmultGold[2], UI.COLORS.xmultGold[3], xmultActive and 0.30 or 0.12)
    UI.drawRoundedRect("fill", b3X, rowY, boxW, boxH, 8)
    love.graphics.setColor(xmultActive and UI.COLORS.xmultGold or { 0.45, 0.45, 0.50, 0.6 })
    UI.drawRoundedRect("line", b3X, rowY, boxW, boxH, 8)
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.printf("HỆ SỐ XMULT", b3X, rowY + 8, boxW, "center")
    love.graphics.setFont(UI.fonts.huge)
    love.graphics.setColor(xmultActive and UI.COLORS.xmultGold or UI.COLORS.textMuted)
    local xmultText = xmultActive and ("x" .. string.format("%.1f", anim.displayXMult):gsub("%.0$", "")) or "x1.0"
    love.graphics.printf(xmultText, b3X, rowY + 22, boxW, "center")

    -- Operator 3: =
    local op3X = b3X + boxW
    love.graphics.setFont(UI.fonts.large)
    love.graphics.setColor(1, 1, 1, 0.75)
    love.graphics.printf("=", op3X, rowY + 22, opW, "center")

    -- Box 4: SÁT THƯƠNG (HP)
    local b4X = op3X + opW
    love.graphics.setColor(UI.COLORS.hpRed[1], UI.COLORS.hpRed[2], UI.COLORS.hpRed[3], 0.25)
    UI.drawRoundedRect("fill", b4X, rowY, boxW, boxH, 8)
    love.graphics.setColor(UI.COLORS.hpRed)
    UI.drawRoundedRect("line", b4X, rowY, boxW, boxH, 8)
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.printf("SÁT THƯƠNG (HP)", b4X, rowY + 8, boxW, "center")
    love.graphics.setFont(UI.fonts.huge)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf(tostring(anim.displayFinalScore), b4X, rowY + 22, boxW, "center")

    -- 5. Footer Message / Hint
    local footerY = bannerY + 382
    if anim.currentStepIndex > #anim.scoringData.steps then
        if anim.monsterDefeated then
            love.graphics.setFont(UI.fonts.large)
            love.graphics.setColor(UI.COLORS.btnPlay)
            love.graphics.printf("⚔ TIÊU DIỆT QUÁI VẬT! (+ $" .. anim.earnedGold .. " Vàng)", bannerX, footerY, bannerW, "center")
        elseif game.handsRemaining <= 0 then
            love.graphics.setFont(UI.fonts.large)
            love.graphics.setColor(UI.COLORS.multRed)
            love.graphics.printf("HẾT LƯỢT ĐÁNH — BẠN ĐÃ BỊ ĐÁNH BẠI!", bannerX, footerY, bannerW, "center")
        else
            love.graphics.setFont(UI.fonts.medium)
            love.graphics.setColor(UI.COLORS.goldYellow)
            love.graphics.printf("Đã gây " .. anim.displayFinalScore .. " Sát thương vào Quái Vật!", bannerX, footerY, bannerW, "center")
        end
    else
        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(UI.COLORS.textMuted)
        love.graphics.printf("Bước " .. math.min(anim.currentStepIndex, #anim.scoringData.steps) .. "/" .. #anim.scoringData.steps .. "  •  [Nhấp chuột hoặc bấm Phím Cách để tua nhanh]", bannerX, footerY + 8, bannerW, "center")
    end

    -- Floating Texts
    for _, ft in ipairs(anim.floatingTexts) do
        love.graphics.setFont(UI.fonts.large)
        love.graphics.setColor(ft.color[1], ft.color[2], ft.color[3], ft.alpha)
        love.graphics.printf(ft.text, ft.x - 200, ft.y, 400, "center")
    end
end

local function drawMap()
    local winW, winH = love.graphics.getDimensions()
    love.graphics.setColor(0.06, 0.08, 0.11, 1)
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)

    local mx, my = toVirtual(love.mouse.getPosition())
    buttons = {}

    -- Top Header Panel
    love.graphics.setColor(UI.COLORS.panelBg)
    UI.drawRoundedRect("fill", 20, 15, V_WIDTH - 40, 75, 8)
    love.graphics.setColor(UI.COLORS.panelBorder)
    UI.drawRoundedRect("line", 20, 15, V_WIDTH - 40, 75, 8)

    -- Title & Subtitle
    love.graphics.setFont(UI.fonts.large)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.print("BẢN ĐỒ HÀNH TRÌNH — VÙNG ĐẤT " .. game.act .. " (TẦNG " .. (game.map and game.map.currentFloor or 1) .. "/20)", 40, 22)

    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.print("Tiền vàng: $" .. game.gold .. "   |   Thần Bài: " .. #game.deities .. "/5   |   Cuộn chuột hoặc bấm nút điều hướng bên dưới để xem 20 tầng!", 40, 56)

    -- Button Handbook & Deck Viewer
    local btnHandbookMap = {
        id = "open_handbook",
        text = "SỔ TAY [H]",
        x = V_WIDTH - 440,
        y = 25,
        w = 180,
        h = 55,
        color = { 0.22, 0.45, 0.35, 1 },
        font = UI.fonts.regular,
    }
    table.insert(buttons, btnHandbookMap)
    UI.drawButton(btnHandbookMap, mx >= btnHandbookMap.x and mx <= btnHandbookMap.x + btnHandbookMap.w and my >= btnHandbookMap.y and my <= btnHandbookMap.y + btnHandbookMap.h)

    local btnDeck = {
        id = "open_deck_viewer",
        text = "XEM BỘ BÀI [Tab]",
        x = V_WIDTH - 240,
        y = 25,
        w = 200,
        h = 55,
        color = { 0.22, 0.40, 0.60, 1 },
        font = UI.fonts.regular,
    }
    table.insert(buttons, btnDeck)
    UI.drawButton(btnDeck, mx >= btnDeck.x and mx <= btnDeck.x + btnDeck.w and my >= btnDeck.y and my <= btnDeck.y + btnDeck.h)

    -- Draw the Map Nodes and Connections
    Map.draw(game.map, mx, my, UI)

    -- Map Navigation & Scroll Buttons at Bottom
    local btnScrollStart = {
        id = "map_scroll_start",
        text = "◄ ĐẦU BẢN ĐỒ (T1)",
        x = 40,
        y = V_HEIGHT - 58,
        w = 180,
        h = 42,
        color = { 0.20, 0.28, 0.38, 1 },
        font = UI.fonts.small,
    }
    table.insert(buttons, btnScrollStart)
    UI.drawButton(btnScrollStart, mx >= btnScrollStart.x and mx <= btnScrollStart.x + btnScrollStart.w and my >= btnScrollStart.y and my <= btnScrollStart.y + btnScrollStart.h)

    local btnScrollFocus = {
        id = "map_scroll_focus",
        text = "TẦNG HIỆN TẠI (T" .. (game.map and game.map.currentFloor or 1) .. ")",
        x = 235,
        y = V_HEIGHT - 58,
        w = 200,
        h = 42,
        color = UI.COLORS.btnPlay,
        font = UI.fonts.small,
    }
    table.insert(buttons, btnScrollFocus)
    UI.drawButton(btnScrollFocus, mx >= btnScrollFocus.x and mx <= btnScrollFocus.x + btnScrollFocus.w and my >= btnScrollFocus.y and my <= btnScrollFocus.y + btnScrollFocus.h)

    local btnScrollEnd = {
        id = "map_scroll_end",
        text = "TRÙM TỐI CAO (T20) ►",
        x = 450,
        y = V_HEIGHT - 58,
        w = 200,
        h = 42,
        color = { 0.55, 0.22, 0.22, 1 },
        font = UI.fonts.small,
    }
    table.insert(buttons, btnScrollEnd)
    UI.drawButton(btnScrollEnd, mx >= btnScrollEnd.x and mx <= btnScrollEnd.x + btnScrollEnd.w and my >= btnScrollEnd.y and my <= btnScrollEnd.y + btnScrollEnd.h)
end

local function drawEventState()
    local winW, winH = love.graphics.getDimensions()
    love.graphics.setColor(0.07, 0.08, 0.12, 1)
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)

    local mx, my = toVirtual(love.mouse.getPosition())
    buttons = {}

    local evt = game.currentEvent
    if not evt then return end

    -- Event Title & Subtitle
    love.graphics.setFont(UI.fonts.huge)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf(evt.title, 0, 40, V_WIDTH, "center")

    love.graphics.setFont(UI.fonts.medium)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.printf(evt.subtitle, 0, 95, V_WIDTH, "center")

    -- Story panel
    local storyW = 880
    local storyH = 80
    local storyX = (V_WIDTH - storyW) / 2
    local storyY = 135

    love.graphics.setColor(0.12, 0.14, 0.18, 0.85)
    UI.drawRoundedRect("fill", storyX, storyY, storyW, storyH, 8)
    love.graphics.setColor(0.28, 0.35, 0.45, 0.6)
    UI.drawRoundedRect("line", storyX, storyY, storyW, storyH, 8)

    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.printf(evt.desc, storyX + 20, storyY + 16, storyW - 40, "center")

    if game.eventOutcomeText then
        -- Outcome Box
        local outW = 740
        local outH = 170
        local outX = (V_WIDTH - outW) / 2
        local outY = 260

        love.graphics.setColor(0.12, 0.18, 0.16, 0.95)
        UI.drawRoundedRect("fill", outX, outY, outW, outH, 10)
        love.graphics.setLineWidth(2)
        love.graphics.setColor(UI.COLORS.hpGreen)
        UI.drawRoundedRect("line", outX, outY, outW, outH, 10)

        love.graphics.setFont(UI.fonts.large)
        love.graphics.setColor(UI.COLORS.goldYellow)
        love.graphics.printf("KẾT QUẢ KỲ NGỘ", outX, outY + 22, outW, "center")

        love.graphics.setFont(UI.fonts.medium)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(game.eventOutcomeText, outX + 24, outY + 68, outW - 48, "center")

        local btnContinue = {
            id = "event_continue",
            text = "TIẾP TỤC HÀNH TRÌNH ->",
            x = (V_WIDTH - 300) / 2,
            y = 480,
            w = 300,
            h = 55,
            color = UI.COLORS.btnPlay,
            font = UI.fonts.regular,
        }
        table.insert(buttons, btnContinue)
        UI.drawButton(btnContinue, mx >= btnContinue.x and mx <= btnContinue.x + btnContinue.w and my >= btnContinue.y and my <= btnContinue.y + btnContinue.h)
    else
        -- 3 Option Cards
        local optW = 350
        local optH = 340
        local startX = (V_WIDTH - (3 * optW + 2 * 25)) / 2
        local optY = 250

        for i, opt in ipairs(evt.options) do
            local ox = startX + (i - 1) * (optW + 25)
            local isHovered = (mx >= ox and mx <= ox + optW and my >= optY and my <= optY + optH)

            love.graphics.setColor(0.14, 0.17, 0.22, 1)
            UI.drawRoundedRect("fill", ox, optY, optW, optH, 10)
            love.graphics.setLineWidth(isHovered and 3 or 1.5)
            love.graphics.setColor(isHovered and UI.COLORS.goldYellow or { 0.32, 0.40, 0.50, 0.8 })
            UI.drawRoundedRect("line", ox, optY, optW, optH, 10)

            -- Option Number & Title
            love.graphics.setFont(UI.fonts.medium)
            love.graphics.setColor(UI.COLORS.goldYellow)
            love.graphics.printf("Lựa chọn " .. i, ox, optY + 18, optW, "center")

            love.graphics.setFont(UI.fonts.large)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf(opt.title, ox + 15, optY + 52, optW - 30, "center")

            -- Option Desc
            love.graphics.setFont(UI.fonts.small)
            love.graphics.setColor(UI.COLORS.textLight)
            love.graphics.printf(opt.desc, ox + 20, optY + 125, optW - 40, "center")

            -- Select button
            local btnOpt = {
                id = "event_opt_" .. i,
                text = "CHỌN HƯỚNG NÀY",
                x = ox + 40,
                y = optY + optH - 60,
                w = optW - 80,
                h = 44,
                color = UI.COLORS.btnPlay,
                font = UI.fonts.regular,
                optIndex = i,
            }
            table.insert(buttons, btnOpt)
            UI.drawButton(btnOpt, mx >= btnOpt.x and mx <= btnOpt.x + btnOpt.w and my >= btnOpt.y and my <= btnOpt.y + btnOpt.h)
        end
    end
end

local function drawBossDeityDraftState()
    local winW, winH = love.graphics.getDimensions()
    love.graphics.setColor(0.08, 0.05, 0.10, 1)
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)

    local mx, my = toVirtual(love.mouse.getPosition())
    buttons = {}

    love.graphics.setFont(UI.fonts.huge)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf("CHIẾN THẮNG TRÙM KHU VỰC!", 0, 40, V_WIDTH, "center")

    love.graphics.setFont(UI.fonts.large)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Hai Vị Thần Bài Giáng Lâm — Hãy Chọn 1 Trong 2 Vị Thần:", 0, 100, V_WIDTH, "center")

    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.printf("Thần bài sở hữu sức mạnh tối thượng giúp nhân bội số Mult, cấp thêm Chips hoặc bảo hộ lượt chơi!", 0, 135, V_WIDTH, "center")

    local deities = game.bossDeityDraft or {}
    local cardW = 390
    local cardH = 430
    local startX = (V_WIDTH - (2 * cardW + 60)) / 2
    local cardY = 185

    for i, d in ipairs(deities) do
        local dx = startX + (i - 1) * (cardW + 60)
        local isHovered = (mx >= dx and mx <= dx + cardW and my >= cardY and my <= cardY + cardH)

        love.graphics.setColor(0.14, 0.16, 0.22, 1)
        UI.drawRoundedRect("fill", dx, cardY, cardW, cardH, 12)

        local borderCol = UI.COLORS.goldYellow
        if d.rarity == "legendary" then borderCol = { 0.95, 0.75, 0.10, 1 }
        elseif d.rarity == "rare" then borderCol = { 0.20, 0.60, 1.0, 1 }
        end

        love.graphics.setLineWidth(isHovered and 3.5 or 2)
        love.graphics.setColor(borderCol)
        UI.drawRoundedRect("line", dx, cardY, cardW, cardH, 12)

        -- Icon circle
        love.graphics.setColor(borderCol[1], borderCol[2], borderCol[3], 0.2)
        love.graphics.circle("fill", dx + cardW / 2, cardY + 70, 45)
        love.graphics.setColor(borderCol)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", dx + cardW / 2, cardY + 70, 45)

        -- Lightning bolt polygon icon
        love.graphics.polygon("fill",
            dx + cardW / 2 + 5, cardY + 45,
            dx + cardW / 2 - 12, cardY + 70,
            dx + cardW / 2 + 2, cardY + 70,
            dx + cardW / 2 - 5, cardY + 95,
            dx + cardW / 2 + 12, cardY + 68,
            dx + cardW / 2 - 2, cardY + 68
        )

        -- Name
        love.graphics.setFont(UI.fonts.large)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(d.name, dx + 10, cardY + 130, cardW - 20, "center")

        -- Rarity tag
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(borderCol)
        love.graphics.printf(d.rarity:upper() .. " DEITY", dx, cardY + 165, cardW, "center")

        -- Description
        love.graphics.setFont(UI.fonts.regular)
        love.graphics.setColor(UI.COLORS.textLight)
        love.graphics.printf(d.desc, dx + 24, cardY + 205, cardW - 48, "center")

        -- Choose Button
        local btnChoose = {
            id = "boss_deity_" .. i,
            text = "THỈNH VỊ THẦN NÀY",
            x = dx + 40,
            y = cardY + cardH - 65,
            w = cardW - 80,
            h = 48,
            color = UI.COLORS.btnPlay,
            font = UI.fonts.regular,
            deityIndex = i,
        }
        table.insert(buttons, btnChoose)
        UI.drawButton(btnChoose, mx >= btnChoose.x and mx <= btnChoose.x + btnChoose.w and my >= btnChoose.y and my <= btnChoose.y + btnChoose.h)
    end
end

local function drawDeckViewerModal()
    -- Overlay dimming
    local winW, winH = love.graphics.getDimensions()
    love.graphics.setColor(0, 0, 0, 0.80)
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)

    local mx, my = toVirtual(love.mouse.getPosition())
    local modalW = 1180
    local modalH = 650
    local modalX = (V_WIDTH - modalW) / 2
    local modalY = (V_HEIGHT - modalH) / 2

    -- Modal background & border
    love.graphics.setColor(0.10, 0.12, 0.16, 0.98)
    UI.drawRoundedRect("fill", modalX, modalY, modalW, modalH, 12)
    love.graphics.setLineWidth(2.5)
    love.graphics.setColor(UI.COLORS.goldYellow)
    UI.drawRoundedRect("line", modalX, modalY, modalW, modalH, 12)

    -- Header
    love.graphics.setFont(UI.fonts.large)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.print("TOÀN BỘ BỘ BÀI HIỆN TẠI & BẢNG BÍ TỊCH", modalX + 24, modalY + 18)

    -- Close button
    local closeBtn = {
        id = "close_deck_viewer",
        text = "ĐÓNG [Esc]",
        x = modalX + modalW - 160,
        y = modalY + 15,
        w = 140,
        h = 38,
        color = UI.COLORS.btnDiscard,
        font = UI.fonts.regular,
    }
    UI.drawButton(closeBtn, mx >= closeBtn.x and mx <= closeBtn.x + closeBtn.w and my >= closeBtn.y and my <= closeBtn.y + closeBtn.h)

    -- Gather all cards in the full deck
    local allCards = {}
    if (state == "playing" or state == "scoring") and (#game.hand > 0 or #game.deck > 0 or #game.discardPile > 0) then
        for _, c in ipairs(game.hand) do table.insert(allCards, c) end
        for _, c in ipairs(game.deck) do table.insert(allCards, c) end
        for _, c in ipairs(game.discardPile) do table.insert(allCards, c) end
    else
        for _, c in ipairs(game.persistentDeck or {}) do table.insert(allCards, c) end
    end

    -- Filter cards
    local filteredCards = {}
    local suitCounts = { aurelia = 0, elaris = 0, vharos = 0, valoria = 0 }
    local equippedCount = 0

    for _, c in ipairs(allCards) do
        local s = c.suit
        if s == "hearts" then s = "aurelia"
        elseif s == "diamonds" then s = "valoria"
        elseif s == "clubs" then s = "elaris"
        elseif s == "spades" then s = "vharos" end

        if suitCounts[s] then
            suitCounts[s] = suitCounts[s] + 1
        end
        local hasEq = (c.equipments and #c.equipments > 0)
        if hasEq then equippedCount = equippedCount + 1 end

        if deckViewerFilter == "all" then
            table.insert(filteredCards, c)
        elseif deckViewerFilter == "equipped" and hasEq then
            table.insert(filteredCards, c)
        elseif deckViewerFilter == s or deckViewerFilter == c.suit then
            table.insert(filteredCards, c)
        end
    end

    -- Left Column: Cards (Width 680)
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.print("Tổng cộng: " .. #allCards .. " lá  (☀️ Aurelia: " .. suitCounts.aurelia .. " | 🌲 Elaris: " .. suitCounts.elaris .. " | 🔥 Vharos: " .. suitCounts.vharos .. " | ⚔️ Valoria: " .. suitCounts.valoria .. " | Đã khảm: " .. equippedCount .. " lá)", modalX + 24, modalY + 58)

    -- Filter Tabs
    local filterTabs = {
        { id = "all", text = "Tất cả (" .. #allCards .. ")" },
        { id = "aurelia", text = "☀️ Aurelia (" .. suitCounts.aurelia .. ")" },
        { id = "elaris", text = "🌲 Elaris (" .. suitCounts.elaris .. ")" },
        { id = "vharos", text = "🔥 Vharos (" .. suitCounts.vharos .. ")" },
        { id = "valoria", text = "⚔️ Valoria (" .. suitCounts.valoria .. ")" },
        { id = "equipped", text = "💎 Đã Khảm (" .. equippedCount .. ")" },
    }
    local tabStartX = modalX + 24
    local tabY = modalY + 86
    local tabW = 108
    local tabH = 30

    for idx, tab in ipairs(filterTabs) do
        local tx = tabStartX + (idx - 1) * (tabW + 6)
        local isSelected = (deckViewerFilter == tab.id)
        local isHovered = (mx >= tx and mx <= tx + tabW and my >= tabY and my <= tabY + tabH)

        love.graphics.setColor(isSelected and UI.COLORS.btnPlay or (isHovered and { 0.25, 0.35, 0.45, 1 } or { 0.18, 0.22, 0.28, 1 }))
        UI.drawRoundedRect("fill", tx, tabY, tabW, tabH, 5)
        love.graphics.setColor(isSelected and UI.COLORS.goldYellow or { 0.35, 0.45, 0.55, 0.8 })
        UI.drawRoundedRect("line", tx, tabY, tabW, tabH, 5)

        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(tab.text, tx, tabY + 8, tabW, "center")
    end

    -- Draw Filtered Cards Grid
    local cardGridX = modalX + 24
    local cardGridY = modalY + 128
    local cw = 74
    local ch = 108
    local cgap = 10
    local cols = 8
    local hoveredDeckCard = nil

    for i, c in ipairs(filteredCards) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local cx = cardGridX + col * (cw + cgap)
        local cy = cardGridY + row * (ch + cgap)

        if cy + ch <= modalY + modalH - 20 then
            local isHov = (mx >= cx and mx <= cx + cw and my >= cy and my <= cy + ch)
            if isHov then hoveredDeckCard = c end

            c.hovered = isHov
            UI.drawCard(c, cx, cy, cw, ch)
        end
    end

    -- Divider Line
    love.graphics.setLineWidth(2)
    love.graphics.setColor(UI.COLORS.panelBorder)
    love.graphics.line(modalX + 710, modalY + 70, modalX + 710, modalY + modalH - 25)

    -- Right Column: Poker Hand Books / Progression
    local rightX = modalX + 725
    local rightW = modalW - (rightX - modalX) - 20

    love.graphics.setFont(UI.fonts.medium)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.print("BẢNG BÍ TỊCH CÁC TAY BÀI", rightX, modalY + 65)

    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.print("Chỉ các tay bài đã mở khóa mới có thể đánh ra và kích hoạt điểm!", rightX, modalY + 92)

    -- List of Poker Hands
    local handList = {
        { id = "high_card", name = "ĐƠN THỦ", poker = "High Card", req = 1, base = "5 Chip x 1 Mult" },
        { id = "pair", name = "SONG ĐAO", poker = "Đôi (Pair)", req = 2, base = "10 Chip x 2 Mult" },
        { id = "two_pair", name = "SONG ĐÔI", poker = "Hai Đôi (Two Pair)", req = 4, base = "20 Chip x 2 Mult" },
        { id = "three_of_a_kind", name = "TAM HOA", poker = "Sám Cô (3 of a Kind)", req = 3, base = "30 Chip x 3 Mult" },
        { id = "straight", name = "TRƯỜNG LONG", poker = "Sảnh (Straight)", req = 5, base = "30 Chip x 4 Mult" },
        { id = "flush", name = "ĐỒNG KHÍ", poker = "Thùng (Flush)", req = 5, base = "35 Chip x 4 Mult" },
        { id = "full_house", name = "HỖN NGUYÊN", poker = "Cù Lũ (Full House)", req = 5, base = "40 Chip x 4 Mult" },
        { id = "four_of_a_kind", name = "TỨ TƯỢNG", poker = "Tứ Quý (4 of a Kind)", req = 4, base = "60 Chip x 7 Mult" },
        { id = "straight_flush", name = "VẠN KIẾM QUY TÔNG", poker = "Thùng Phá Sảnh", req = 5, base = "100 Chip x 8 Mult" },
    }

    local handItemY = modalY + 115
    local handItemH = 52

    for idx, h in ipairs(handList) do
        local hy = handItemY + (idx - 1) * (handItemH + 6)
        local isUnlocked = (game.unlockedHands[h.id] == true)

        love.graphics.setColor(isUnlocked and { 0.14, 0.20, 0.16, 0.9 } or { 0.14, 0.15, 0.18, 0.7 })
        UI.drawRoundedRect("fill", rightX, hy, rightW, handItemH, 6)

        love.graphics.setLineWidth(1)
        love.graphics.setColor(isUnlocked and UI.COLORS.hpGreen or { 0.3, 0.35, 0.4, 0.5 })
        UI.drawRoundedRect("line", rightX, hy, rightW, handItemH, 6)

        -- Hand Title
        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(isUnlocked and UI.COLORS.goldYellow or UI.COLORS.textMuted)
        love.graphics.print(h.name .. " (" .. h.poker .. ")", rightX + 12, hy + 8)

        -- Hand Stats & Status Tag
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(UI.COLORS.textLight)
        love.graphics.print("Cần: " .. h.req .. " lá   |   Cơ bản: " .. h.base, rightX + 12, hy + 28)

        if isUnlocked then
            love.graphics.setFont(UI.fonts.tiny)
            love.graphics.setColor(UI.COLORS.hpGreen)
            love.graphics.printf("[ĐÃ MỞ]", rightX + rightW - 90, hy + 16, 80, "right")
        else
            love.graphics.setFont(UI.fonts.tiny)
            love.graphics.setColor(UI.COLORS.multRed)
            love.graphics.printf("[CHƯA MỞ]", rightX + rightW - 120, hy + 16, 110, "right")
        end
    end

    -- Card Equipment Hover Tooltip inside Modal
    if hoveredDeckCard then
        local c = hoveredDeckCard
        local ttW = 280
        local ttH = 30 + (c.equipments and #c.equipments or 0) * 26 + 30
        local ttx = math.min(V_WIDTH - ttW - 20, math.max(20, mx + 15))
        local tty = math.max(30, my - ttH - 10)

        love.graphics.setColor(0.08, 0.10, 0.12, 0.98)
        UI.drawRoundedRect("fill", ttx, tty, ttW, ttH, 6)
        love.graphics.setColor(UI.COLORS.goldYellow)
        UI.drawRoundedRect("line", ttx, tty, ttW, ttH, 6)

        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("Lá: " .. c.rankName .. " " .. c.suitSymbol .. " (Gốc: +" .. c.baseChips .. " Chips)", ttx + 10, tty + 8)

        local eqCount = c.equipments and #c.equipments or 0
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(UI.COLORS.textMuted)
        love.graphics.print("Trang bị khảm trên lá (" .. eqCount .. "/5 ô):", ttx + 10, tty + 30)

        if eqCount == 0 then
            love.graphics.setColor(UI.COLORS.textMuted)
            love.graphics.print("(Chưa khảm trang bị nào)", ttx + 15, tty + 48)
        else
            for s, eq in ipairs(c.equipments) do
                love.graphics.setColor(eq.color or UI.COLORS.textLight)
                love.graphics.print("• " .. eq.name .. ": " .. eq.desc, ttx + 12, tty + 32 + s * 22)
            end
        end
    end
end

local function drawChestState()
    local winW, winH = love.graphics.getDimensions()
    love.graphics.setColor(0.08, 0.06, 0.12, 1)
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)

    local mx, my = toVirtual(love.mouse.getPosition())

    love.graphics.setFont(UI.fonts.huge)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf("👑 RƯƠNG THƯỞNG BOSS CHIẾN THẮNG! 👑", 0, 40, V_WIDTH, "center")

    love.graphics.setFont(UI.fonts.medium)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.printf("Chọn 1 trong 3 phần thưởng để bổ sung vào kho báu của bạn:", 0, 105, V_WIDTH, "center")

    buttons = {}
    local boxW = 340
    local boxH = 380
    local startX = (V_WIDTH - (3 * boxW + 2 * 30)) / 2
    local boxY = 160

    for i, rew in ipairs(chestRewards) do
        local bx = startX + (i - 1) * (boxW + 30)
        local isHovered = (mx >= bx and mx <= bx + boxW and my >= boxY and my <= boxY + boxH)

        love.graphics.setColor(0.14, 0.16, 0.22, 1)
        UI.drawRoundedRect("fill", bx, boxY, boxW, boxH, 12)

        love.graphics.setLineWidth(isHovered and 3 or 1.5)
        love.graphics.setColor(rew.color or UI.COLORS.goldYellow)
        UI.drawRoundedRect("line", bx, boxY, boxW, boxH, 12)

        -- Title
        love.graphics.setFont(UI.fonts.medium)
        love.graphics.setColor(rew.color or UI.COLORS.goldYellow)
        love.graphics.printf(rew.title, bx + 10, boxY + 20, boxW - 20, "center")

        -- Card or Gem Display
        if rew.type == "card" then
            local cw = 90
            local ch = 130
            UI.drawCard(rew.card, bx + (boxW - cw) / 2, boxY + 65, cw, ch)
        else
            -- Gem icon box
            love.graphics.setColor(rew.item.color[1], rew.item.color[2], rew.item.color[3], 0.25)
            UI.drawRoundedRect("fill", bx + (boxW - 120) / 2, boxY + 70, 120, 100, 8)
            love.graphics.setColor(rew.item.color)
            love.graphics.circle("fill", bx + boxW / 2, boxY + 120, 32)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setFont(UI.fonts.large)
            love.graphics.printf(rew.item.name, bx + 10, boxY + 175, boxW - 20, "center")
        end

        -- Description
        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(UI.COLORS.textLight)
        love.graphics.printf(rew.desc, bx + 16, boxY + 225, boxW - 32, "center")

        -- Select Button
        local btnChoose = {
            id = "chest_" .. i,
            text = (rew.type == "card") and "NHẬN VÀO BỘ BÀI" or "GẮN VÀO LÁ BÀI",
            x = bx + 40,
            y = boxY + boxH - 55,
            w = boxW - 80,
            h = 42,
            color = UI.COLORS.btnPlay,
            font = UI.fonts.regular,
            rewardIndex = i,
        }
        table.insert(buttons, btnChoose)
        UI.drawButton(btnChoose, mx >= btnChoose.x and mx <= btnChoose.x + btnChoose.w and my >= btnChoose.y and my <= btnChoose.y + btnChoose.h)
    end
end

local function drawSocketingView()
    local winW, winH = love.graphics.getDimensions()
    love.graphics.setColor(0.08, 0.08, 0.12, 1)
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)

    local mx, my = toVirtual(love.mouse.getPosition())

    love.graphics.setFont(UI.fonts.large)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf("CHỌN 1 LÁ BÀI TRÊN TAY ĐỂ GẮN TRANG BỊ", 0, 40, V_WIDTH, "center")

    love.graphics.setFont(UI.fonts.medium)
    love.graphics.setColor(pendingEquipment.color)
    love.graphics.printf("Trang bị: " .. pendingEquipment.name .. " (" .. pendingEquipment.desc .. ")", 0, 85, V_WIDTH, "center")

    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.printf("Mỗi lá bài mang tối đa 5 ô trang bị. Nhấp trực tiếp vào lá bài bạn muốn gắn!", 0, 125, V_WIDTH, "center")

    local allCards = getAllDeckCards()
    for i, c in ipairs(allCards) do
        local cx, cy, cardW, cardH = getCardGridPos(i, #allCards, 100, 145, 16, 32, 8, 240)
        local isHovered = (mx >= cx and mx <= cx + cardW and my >= cy and my <= cy + cardH)

        c.hovered = isHovered
        UI.drawCard(c, cx, cy, cardW, cardH)

        -- Slot count tag below card
        local slotCount = c.equipments and #c.equipments or 0
        local isFull = (slotCount >= Equipment.MAX_SLOTS)

        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(isFull and UI.COLORS.multRed or UI.COLORS.chipsBlue)
        love.graphics.printf("[" .. slotCount .. "/5 ô]", cx, cy + cardH + 10, cardW, "center")
    end

    buttons = {}
    local btnSkip = {
        id = "skip_socket",
        text = "Bỏ qua trang bị này ->",
        x = (V_WIDTH - 240) / 2,
        y = 540,
        w = 240,
        h = 45,
        color = UI.COLORS.btnNormal,
        font = UI.fonts.regular,
    }
    table.insert(buttons, btnSkip)
    UI.drawButton(btnSkip, mx >= btnSkip.x and mx <= btnSkip.x + btnSkip.w and my >= btnSkip.y and my <= btnSkip.y + btnSkip.h)
end

local function generateTreasureRewards()
    treasureRewards = {}
    local rewardCard = (love.math.random() < 0.5) and Deck.createRewardCard(game.selectedSuit) or Deck.newCard(love.math.random(9, 13), game.selectedSuit)
    table.insert(treasureRewards, {
        type = "card",
        card = rewardCard,
        title = "TIẾP VIỆN: " .. rewardCard.rankName .. " " .. rewardCard.suitName,
        desc = "Nhận lá " .. rewardCard.rankName .. rewardCard.suitSymbol .. " (" .. rewardCard.baseChips .. " Chips, bền " .. rewardCard.rank .. " lần đánh) vào bộ bài!",
        color = rewardCard.color,
    })

    local eq1 = Equipment.getRandomEquipment()
    table.insert(treasureRewards, {
        type = "equipment",
        item = eq1,
        title = "CỔ VẬT: " .. eq1.name,
        desc = eq1.desc,
        color = eq1.color,
    })

    local eq2 = Equipment.getRandomEquipment()
    while eq2.id == eq1.id do
        eq2 = Equipment.getRandomEquipment()
    end
    table.insert(treasureRewards, {
        type = "equipment",
        item = eq2,
        title = "CỔ VẬT: " .. eq2.name,
        desc = eq2.desc,
        color = eq2.color,
    })
end

local function drawTreasureState()
    local winW, winH = love.graphics.getDimensions()
    love.graphics.setColor(0.08, 0.06, 0.12, 1)
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)

    local mx, my = toVirtual(love.mouse.getPosition())

    love.graphics.setFont(UI.fonts.huge)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf("RƯƠNG BÁU CỔ ĐẠI (TẦNG " .. (game.map and game.map.currentFloor or 1) .. ")", 0, 40, V_WIDTH, "center")

    love.graphics.setFont(UI.fonts.medium)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.printf("Bạn khai mở một rương báu cổ xưa. Hãy chọn 1 phần thưởng miễn phí:", 0, 105, V_WIDTH, "center")

    buttons = {}
    local boxW = 340
    local boxH = 380
    local startX = (V_WIDTH - (3 * boxW + 2 * 30)) / 2
    local boxY = 160

    for i, rew in ipairs(treasureRewards) do
        local bx = startX + (i - 1) * (boxW + 30)
        local isHovered = (mx >= bx and mx <= bx + boxW and my >= boxY and my <= boxY + boxH)

        love.graphics.setColor(0.14, 0.16, 0.22, 1)
        UI.drawRoundedRect("fill", bx, boxY, boxW, boxH, 12)

        love.graphics.setLineWidth(isHovered and 3 or 1.5)
        love.graphics.setColor(rew.color or UI.COLORS.goldYellow)
        UI.drawRoundedRect("line", bx, boxY, boxW, boxH, 12)

        -- Title
        love.graphics.setFont(UI.fonts.medium)
        love.graphics.setColor(rew.color or UI.COLORS.goldYellow)
        love.graphics.printf(rew.title, bx + 10, boxY + 20, boxW - 20, "center")

        -- Card or Gem Display
        if rew.type == "card" then
            local cw = 90
            local ch = 130
            UI.drawCard(rew.card, bx + (boxW - cw) / 2, boxY + 65, cw, ch)
        else
            love.graphics.setColor(rew.item.color[1], rew.item.color[2], rew.item.color[3], 0.25)
            UI.drawRoundedRect("fill", bx + (boxW - 120) / 2, boxY + 70, 120, 100, 8)
            love.graphics.setColor(rew.item.color)
            love.graphics.circle("fill", bx + boxW / 2, boxY + 120, 32)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setFont(UI.fonts.large)
            love.graphics.printf(rew.item.name, bx + 10, boxY + 175, boxW - 20, "center")
        end

        -- Description
        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(UI.COLORS.textLight)
        love.graphics.printf(rew.desc, bx + 16, boxY + 225, boxW - 32, "center")

        -- Select Button
        local btnChoose = {
            id = "treasure_" .. i,
            text = (rew.type == "card") and "NHẬN VÀO BỘ BÀI" or "GẮN VÀO LÁ BÀI",
            x = bx + 40,
            y = boxY + boxH - 55,
            w = boxW - 80,
            h = 42,
            color = UI.COLORS.btnPlay,
            font = UI.fonts.regular,
            rewardIndex = i,
        }
        table.insert(buttons, btnChoose)
        UI.drawButton(btnChoose, mx >= btnChoose.x and mx <= btnChoose.x + btnChoose.w and my >= btnChoose.y and my <= btnChoose.y + btnChoose.h)
    end
end

local function drawRestState()
    local winW, winH = love.graphics.getDimensions()
    love.graphics.setColor(0.08, 0.12, 0.10, 1)
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)

    local mx, my = toVirtual(love.mouse.getPosition())
    buttons = {}

    love.graphics.setFont(UI.fonts.huge)
    love.graphics.setColor(UI.COLORS.hpGreen)
    love.graphics.printf("TRẠM NGHỈ & LÒ RÈN CỔ ĐẠI (TẦNG " .. (game.map and game.map.currentFloor or 1) .. ")", 0, 35, V_WIDTH, "center")

    love.graphics.setFont(UI.fonts.medium)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.printf("Nơi lữ khách dừng chân để hồi phục thể lực hoặc mài sắc binh khí trước thềm đại chiến!", 0, 95, V_WIDTH, "center")

    if not restStateData.chosenAction then
        -- Display 2 big choices
        local choiceW = 540
        local choiceH = 360
        local gap = 40
        local startX = (V_WIDTH - (2 * choiceW + gap)) / 2
        local choiceY = 160

        -- Choice 1: Rest (Dưỡng Sức)
        local isHov1 = (mx >= startX and mx <= startX + choiceW and my >= choiceY and my <= choiceY + choiceH)
        love.graphics.setColor(0.12, 0.18, 0.15, 0.95)
        UI.drawRoundedRect("fill", startX, choiceY, choiceW, choiceH, 12)
        love.graphics.setLineWidth(isHov1 and 3 or 1.5)
        love.graphics.setColor(isHov1 and UI.COLORS.goldYellow or UI.COLORS.hpGreen)
        UI.drawRoundedRect("line", startX, choiceY, choiceW, choiceH, 12)

        love.graphics.setFont(UI.fonts.large)
        love.graphics.setColor(UI.COLORS.hpGreen)
        love.graphics.printf("[ DƯỠNG SỨC TIẾP LỰC ]", startX, choiceY + 28, choiceW, "center")

        love.graphics.setFont(UI.fonts.medium)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("+1 Max Hands & +1 Max Discards", startX, choiceY + 80, choiceW, "center")

        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(UI.COLORS.textLight)
        love.graphics.printf("Tăng vĩnh viễn giới hạn Lượt Đánh tối đa (" .. game.maxHands .. " -> " .. (game.maxHands + 1) .. ") và Lượt Đổi bài (" .. game.maxDiscards .. " -> " .. (game.maxDiscards + 1) .. ")!\nĐồng thời hồi phục đầy đủ toàn bộ lượt đánh và đổi bài ngay lập tức!", startX + 30, choiceY + 130, choiceW - 60, "center")

        local btnRest = {
            id = "rest_action_heal",
            text = "CHỌN DƯỠNG SỨC (+1 HAND & +1 DISCARD)",
            x = startX + 40,
            y = choiceY + choiceH - 65,
            w = choiceW - 80,
            h = 46,
            color = UI.COLORS.hpGreen,
            font = UI.fonts.regular,
        }
        table.insert(buttons, btnRest)
        UI.drawButton(btnRest, mx >= btnRest.x and mx <= btnRest.x + btnRest.w and my >= btnRest.y and my <= btnRest.y + btnRest.h)

        -- Choice 2: Forge (Mài Sắc Bài)
        local cx2 = startX + choiceW + gap
        local isHov2 = (mx >= cx2 and mx <= cx2 + choiceW and my >= choiceY and my <= choiceY + choiceH)
        love.graphics.setColor(0.18, 0.14, 0.12, 0.95)
        UI.drawRoundedRect("fill", cx2, choiceY, choiceW, choiceH, 12)
        love.graphics.setLineWidth(isHov2 and 3 or 1.5)
        love.graphics.setColor(isHov2 and UI.COLORS.goldYellow or { 0.95, 0.55, 0.2, 1 })
        UI.drawRoundedRect("line", cx2, choiceY, choiceW, choiceH, 12)

        love.graphics.setFont(UI.fonts.large)
        love.graphics.setColor(UI.COLORS.goldYellow)
        love.graphics.printf("[ LÒ RÈN TÔI LUYỆN: RANK +1 ]", cx2, choiceY + 28, choiceW, "center")

        love.graphics.setFont(UI.fonts.medium)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("Nâng Cấp & Phục Hồi Độ Bền Lá Bài", cx2, choiceY + 80, choiceW, "center")

        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(UI.COLORS.textLight)
        love.graphics.printf("Chọn 1 lá bài trong bộ bài để tăng +1 Rank (Ví dụ: 3 -> 4, A -> 2, 8 -> 9).\nGiúp lá bài tăng thêm Chips cơ bản và kéo dài độ bền thêm 1 lần đánh nữa!", cx2 + 30, choiceY + 130, choiceW - 60, "center")

        local btnForge = {
            id = "rest_action_forge",
            text = "CHỌN TÔI LUYỆN BÀI (+1 RANK)",
            x = cx2 + 40,
            y = choiceY + choiceH - 65,
            w = choiceW - 80,
            h = 46,
            color = { 0.85, 0.45, 0.15, 1 },
            font = UI.fonts.regular,
        }
        table.insert(buttons, btnForge)
        UI.drawButton(btnForge, mx >= btnForge.x and mx <= btnForge.x + btnForge.w and my >= btnForge.y and my <= btnForge.y + btnForge.h)

    elseif restStateData.chosenAction == "forge" and not restStateData.selectedCard then
        -- Select a card to upgrade
        love.graphics.setFont(UI.fonts.medium)
        love.graphics.setColor(UI.COLORS.goldYellow)
        love.graphics.printf("Nhấp trực tiếp vào lá bài bạn muốn nâng cấp Rank (+1 Rank & hồi bền):", 0, 150, V_WIDTH, "center")

        local allCards = getAllDeckCards()
        for i, c in ipairs(allCards) do
            local cx, cy, cw, ch = getCardGridPos(i, #allCards, 100, 145, 16, 32, 8, 250)
            local isHovered = (mx >= cx and mx <= cx + cw and my >= cy and my <= cy + ch)
            c.hovered = isHovered
            UI.drawCard(c, cx, cy, cw, ch)

            love.graphics.setFont(UI.fonts.small)
            love.graphics.setColor(UI.COLORS.goldYellow)
            local nextRank = Deck.RANK_NAMES[c.rank + 1] or "Max"
            love.graphics.printf("➔ " .. nextRank, cx, cy + ch + 10, cw, "center")
        end

    else
        -- Outcome confirmation
        love.graphics.setColor(0.12, 0.16, 0.20, 0.95)
        UI.drawRoundedRect("fill", 240, 200, V_WIDTH - 480, 240, 12)
        love.graphics.setColor(UI.COLORS.hpGreen)
        UI.drawRoundedRect("line", 240, 200, V_WIDTH - 480, 240, 12)

        love.graphics.setFont(UI.fonts.large)
        love.graphics.setColor(UI.COLORS.hpGreen)
        love.graphics.printf("✨ THỰC HIỆN THÀNH CÔNG! ✨", 240, 230, V_WIDTH - 480, "center")

        love.graphics.setFont(UI.fonts.medium)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(restStateData.message or "Đã hoàn tất nghỉ ngơi!", 260, 285, V_WIDTH - 520, "center")

        local btnLeaveRest = {
            id = "leave_rest",
            text = "TIẾP TỤC HÀNH TRÌNH (VỀ BẢN ĐỒ) ->",
            x = (V_WIDTH - 380) / 2,
            y = 370,
            w = 380,
            h = 50,
            color = UI.COLORS.btnPlay,
            font = UI.fonts.regular,
        }
        table.insert(buttons, btnLeaveRest)
        UI.drawButton(btnLeaveRest, mx >= btnLeaveRest.x and mx <= btnLeaveRest.x + btnLeaveRest.w and my >= btnLeaveRest.y and my <= btnLeaveRest.y + btnLeaveRest.h)
    end
end

local function drawShopTransferView()
    -- Overlay
    local winW, winH = love.graphics.getDimensions()
    love.graphics.setColor(0.08, 0.10, 0.13, 1)
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)

    local mx, my = toVirtual(love.mouse.getPosition())
    buttons = {}

    -- Title
    love.graphics.setFont(UI.fonts.large)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf("HOÁN ĐỔI TRANG BỊ GIỮA CÁC LÁ BÀI (SHOP TRANSFER)", 0, 25, V_WIDTH, "center")

    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.printf("1. Chọn Lá Nguồn -> 2. Chọn Trang Bị Muốn Gỡ -> 3. Chọn Lá Đích Để Gắn Sang (Tối đa 5 ô/lá)", 0, 62, V_WIDTH, "center")

    local allCards = getAllDeckCards()

    -- Auto select first equipped card if none selected
    if not transferSourceCard then
        for _, c in ipairs(allCards) do
            if c.equipments and #c.equipments > 0 then
                transferSourceCard = c
                break
            end
        end
    end

    -- Section 1: Choose Source Card
    love.graphics.setFont(UI.fonts.medium)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("BƯỚC 1: Chọn lá bài nguồn (Đang mang trang bị):", 80, 95)

    local cw = 90
    local ch = 130
    local gap = 18
    local totalW = #allCards * cw + math.max(0, #allCards - 1) * gap
    local startX = math.max(80, (V_WIDTH - totalW) / 2)
    local cardY = 125

    for i, c in ipairs(allCards) do
        local cx = startX + (i - 1) * (cw + gap)
        local isSelected = (transferSourceCard == c)
        local isHovered = (mx >= cx and mx <= cx + cw and my >= cardY and my <= cardY + ch)
        c.hovered = isHovered

        UI.drawCard(c, cx, cardY, cw, ch)

        if isSelected then
            love.graphics.setLineWidth(3.5)
            love.graphics.setColor(UI.COLORS.goldYellow)
            UI.drawRoundedRect("line", cx - 3, cardY - 3, cw + 6, ch + 6, 10)
        end

        local eqCount = c.equipments and #c.equipments or 0
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(eqCount > 0 and UI.COLORS.chipsBlue or UI.COLORS.textMuted)
        love.graphics.printf(eqCount .. "/5 ô", cx, cardY + ch + 6, cw, "center")
    end

    -- Section 2: Choose Equipment slot from transferSourceCard
    if transferSourceCard then
        love.graphics.setFont(UI.fonts.medium)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("BƯỚC 2: Chọn trang bị muốn gỡ từ Lá " .. transferSourceCard.rankName .. transferSourceCard.suitSymbol .. ":", 80, 285)

        local eqList = transferSourceCard.equipments or {}
        if #eqList == 0 then
            love.graphics.setFont(UI.fonts.regular)
            love.graphics.setColor(UI.COLORS.multRed)
            love.graphics.print("Lá bài này hiện không có trang bị nào để gỡ!", 100, 320)
        else
            local eqBoxW = 210
            local eqBoxH = 65
            for idx, eq in ipairs(eqList) do
                local ex = 80 + (idx - 1) * (eqBoxW + 16)
                local ey = 320
                local isEqSel = (transferSourceEqIndex == idx)
                local isEqHov = (mx >= ex and mx <= ex + eqBoxW and my >= ey and my <= ey + eqBoxH)

                love.graphics.setColor(isEqSel and { 0.25, 0.35, 0.45, 1 } or { 0.16, 0.20, 0.25, 0.9 })
                UI.drawRoundedRect("fill", ex, ey, eqBoxW, eqBoxH, 8)
                love.graphics.setLineWidth(isEqSel and 3 or 1.5)
                love.graphics.setColor(isEqSel and UI.COLORS.goldYellow or (eq.color or UI.COLORS.panelBorder))
                UI.drawRoundedRect("line", ex, ey, eqBoxW, eqBoxH, 8)

                love.graphics.setFont(UI.fonts.small)
                love.graphics.setColor(eq.color or 1, 1, 1, 1)
                love.graphics.print("[Ô " .. idx .. "] " .. eq.name, ex + 10, ey + 8)

                love.graphics.setFont(UI.fonts.tiny)
                love.graphics.setColor(UI.COLORS.textLight)
                love.graphics.printf(eq.desc, ex + 10, ey + 30, eqBoxW - 20, "left")
            end
        end
    end

    -- Section 3: Choose Target Card
    if transferSourceCard and transferSourceEqIndex and transferSourceCard.equipments and transferSourceCard.equipments[transferSourceEqIndex] then
        local chosenEq = transferSourceCard.equipments[transferSourceEqIndex]
        love.graphics.setFont(UI.fonts.medium)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("BƯỚC 3: Chọn lá bài đích để nhận [" .. chosenEq.name .. "]:", 80, 410)

        local targetY = 445
        for i, c in ipairs(allCards) do
            local cx = startX + (i - 1) * (cw + gap)
            local isSameCard = (c == transferSourceCard)
            local isFull = (c.equipments and #c.equipments >= 5)
            local canTransfer = not isSameCard and not isFull
            local isHovered = (canTransfer and mx >= cx and mx <= cx + cw and my >= targetY and my <= targetY + ch)
            c.hovered = isHovered

            UI.drawCard(c, cx, targetY, cw, ch)

            if isSameCard then
                love.graphics.setColor(0, 0, 0, 0.6)
                UI.drawRoundedRect("fill", cx, targetY, cw, ch, 8)
                love.graphics.setFont(UI.fonts.tiny)
                love.graphics.setColor(UI.COLORS.textMuted)
                love.graphics.printf("[Nguồn]", cx, targetY + ch / 2 - 8, cw, "center")
            elseif isFull then
                love.graphics.setColor(0, 0, 0, 0.6)
                UI.drawRoundedRect("fill", cx, targetY, cw, ch, 8)
                love.graphics.setFont(UI.fonts.tiny)
                love.graphics.setColor(UI.COLORS.multRed)
                love.graphics.printf("[Đã Đầy 5/5]", cx, targetY + ch / 2 - 8, cw, "center")
            else
                love.graphics.setFont(UI.fonts.tiny)
                love.graphics.setColor(UI.COLORS.hpGreen)
                love.graphics.printf("Gắn vào đây", cx, targetY + ch + 6, cw, "center")
            end
        end
    end

    -- Message banner
    if transferMessage then
        love.graphics.setFont(UI.fonts.medium)
        love.graphics.setColor(UI.COLORS.goldYellow)
        love.graphics.printf(transferMessage, 80, 630, V_WIDTH - 420, "left")
    end

    -- Close / Return button
    local btnCloseTransfer = {
        id = "close_shop_transfer",
        text = "XONG / QUAY LẠI CỬA HÀNG [Esc]",
        x = V_WIDTH - 320,
        y = 615,
        w = 280,
        h = 50,
        color = UI.COLORS.btnPlay,
        font = UI.fonts.regular,
    }
    table.insert(buttons, btnCloseTransfer)
    UI.drawButton(btnCloseTransfer, mx >= btnCloseTransfer.x and mx <= btnCloseTransfer.x + btnCloseTransfer.w and my >= btnCloseTransfer.y and my <= btnCloseTransfer.y + btnCloseTransfer.h)
end

local function drawCardInspectorModal(card)
    if not card then return end
    -- Overlay dimming
    local winW, winH = love.graphics.getDimensions()
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)

    local mx, my = toVirtual(love.mouse.getPosition())
    local modalW = 860
    local modalH = 540
    local modalX = (V_WIDTH - modalW) / 2
    local modalY = (V_HEIGHT - modalH) / 2

    -- Modal Box
    love.graphics.setColor(0.09, 0.11, 0.15, 0.98)
    UI.drawRoundedRect("fill", modalX, modalY, modalW, modalH, 12)
    love.graphics.setLineWidth(2.5)
    love.graphics.setColor(card.color or UI.COLORS.goldYellow)
    UI.drawRoundedRect("line", modalX, modalY, modalW, modalH, 12)

    -- Title (Shortened to not overlap close button)
    love.graphics.setFont(UI.fonts.large)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.print("CHI TIẾT LÁ BÀI & TRANG BỊ KHẢM", modalX + 28, modalY + 20)

    -- Close button
    local btnClose = {
        id = "close_inspector",
        text = "ĐÓNG [Esc / Chuột Phải]",
        x = modalX + modalW - 240,
        y = modalY + 18,
        w = 210,
        h = 36,
        color = UI.COLORS.btnDiscard,
        font = UI.fonts.small,
    }
    table.insert(buttons, btnClose)
    UI.drawButton(btnClose, mx >= btnClose.x and mx <= btnClose.x + btnClose.w and my >= btnClose.y and my <= btnClose.y + btnClose.h)

    -- Left side: Card Art & Durability
    local cardArtW = 150
    local cardArtH = 220
    local cardArtX = modalX + 40
    local cardArtY = modalY + 80
    UI.drawCard(card, cardArtX, cardArtY, cardArtW, cardArtH)

    -- Role & Faction details block under card art
    local durY = cardArtY + cardArtH + 15
    local durH = 175
    love.graphics.setColor(0.14, 0.17, 0.22, 0.9)
    UI.drawRoundedRect("fill", cardArtX, durY, cardArtW, durH, 8)
    love.graphics.setLineWidth(1.5)
    love.graphics.setColor(card.color or UI.COLORS.goldYellow)
    UI.drawRoundedRect("line", cardArtX, durY, cardArtW, durH, 8)

    local role = card.role and Deck.CARD_ROLES[card.role] or Deck.getCardRole(card.rank)
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf(role.icon .. " " .. role.name, cardArtX, durY + 10, cardArtW, "center")

    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(card.color or UI.COLORS.textLight)
    love.graphics.printf("Phe: " .. (card.suitName or "Aurelia"), cardArtX + 8, durY + 32, cardArtW - 16, "center")

    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.printf(role.desc, cardArtX + 8, durY + 54, cardArtW - 16, "left")

    love.graphics.setColor(UI.COLORS.hpGreen)
    love.graphics.printf("Điểm: +" .. card.baseChips .. " Chips", cardArtX + 8, durY + durH - 24, cardArtW - 16, "center")

    -- Right side: 5 Equipment Sockets
    local rightX = modalX + 230
    local rightW = modalW - 260
    love.graphics.setFont(UI.fonts.medium)
    love.graphics.setColor(UI.COLORS.textLight)
    local currentEqCount = card.equipments and #card.equipments or 0
    love.graphics.print("CÁC Ô KHẢM TRANG BỊ (" .. currentEqCount .. "/5 Ô):", rightX, modalY + 80)

    local slotH = 68
    local slotStartY = modalY + 115
    for s = 1, 5 do
        local sy = slotStartY + (s - 1) * (slotH + 12)
        local eq = card.equipments and card.equipments[s]

        if eq then
            love.graphics.setColor(0.16, 0.20, 0.26, 0.95)
            UI.drawRoundedRect("fill", rightX, sy, rightW, slotH, 8)
            love.graphics.setLineWidth(2)
            love.graphics.setColor(eq.color or UI.COLORS.goldYellow)
            UI.drawRoundedRect("line", rightX, sy, rightW, slotH, 8)

            -- Slot badge & name
            love.graphics.setFont(UI.fonts.regular)
            love.graphics.setColor(eq.color or UI.COLORS.goldYellow)
            love.graphics.print("[Ô " .. s .. "/5] " .. eq.name, rightX + 16, sy + 10)

            love.graphics.setFont(UI.fonts.small)
            love.graphics.setColor(UI.COLORS.textLight)
            love.graphics.printf(eq.desc, rightX + 20, sy + 38, rightW - 40, "left")
        else
            love.graphics.setColor(0.11, 0.13, 0.17, 0.6)
            UI.drawRoundedRect("fill", rightX, sy, rightW, slotH, 8)
            love.graphics.setLineWidth(1)
            love.graphics.setColor(0.28, 0.32, 0.38, 0.4)
            UI.drawRoundedRect("line", rightX, sy, rightW, slotH, 8)

            love.graphics.setFont(UI.fonts.small)
            love.graphics.setColor(0.4, 0.45, 0.52, 0.7)
            love.graphics.print("[Ô " .. s .. "/5] Ô Khảm Trống", rightX + 16, sy + 14)

            love.graphics.setFont(UI.fonts.tiny)
            love.graphics.setColor(UI.COLORS.textMuted)
            love.graphics.print("Mua trang bị tại Cửa Hàng hoặc nhặt từ Rương Báu để khảm vào ô này.", rightX + 20, sy + 40)
        end
    end
end

local function drawHandbookModal()
    local winW, winH = love.graphics.getDimensions()
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)

    local mx, my = toVirtual(love.mouse.getPosition())
    local modalW = 960
    local modalH = 650
    local modalX = (V_WIDTH - modalW) / 2
    local modalY = (V_HEIGHT - modalH) / 2

    -- Modal Box
    love.graphics.setColor(0.08, 0.10, 0.14, 0.98)
    UI.drawRoundedRect("fill", modalX, modalY, modalW, modalH, 12)
    love.graphics.setLineWidth(2.5)
    love.graphics.setColor(UI.COLORS.goldYellow)
    UI.drawRoundedRect("line", modalX, modalY, modalW, modalH, 12)

    -- Header Title
    love.graphics.setFont(UI.fonts.large)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.print("SỔ TAY CÁC THẾ BÀI POKER", modalX + 30, modalY + 16)

    -- Subtitle
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.print("9 Tuyệt Kỹ Võ Đạo Thẻ Bài - Kiểm tra điều kiện kích hoạt & trạng thái Mở Khóa Bí Tịch", modalX + 32, modalY + 48)

    -- Close Button
    local btnClose = {
        id = "close_handbook",
        text = "ĐÓNG [Esc / H]",
        x = modalX + modalW - 190,
        y = modalY + 16,
        w = 160,
        h = 36,
        color = UI.COLORS.btnDiscard,
        font = UI.fonts.small,
    }
    table.insert(buttons, btnClose)
    UI.drawButton(btnClose, mx >= btnClose.x and mx <= btnClose.x + btnClose.w and my >= btnClose.y and my <= btnClose.y + btnClose.h)

    local handDescriptions = {
        straight_flush = "5 lá bài vừa có số liên tiếp vừa cùng một chất (Thùng phá sảnh)",
        four_of_a_kind = "4 lá bài có cùng một cấp số / Rank (Tứ quý uy lực)",
        full_house     = "1 bộ ba lá cùng số kết hợp 1 bộ đôi lá cùng số (Cù lũ hỗn nguyên)",
        flush          = "5 lá bài có cùng một chất bài (Thùng đồng khí)",
        straight       = "5 lá bài có cấp số liên tiếp nhau (Sảnh trường long)",
        three_of_a_kind= "3 lá bài có cùng một cấp số / Rank (Sám cô tam hoa)",
        two_pair       = "2 cặp lá bài có cấp số giống nhau (Hai đôi song đôi)",
        pair           = "2 lá bài có cùng một cấp số / Rank (Đôi song đao)",
        high_card      = "1 lá bài có giá trị số cao nhất (Mậu thầu - Luôn mở khóa)",
    }

    local rowY = modalY + 74
    local rowH = 56
    local rowGap = 6

    for idx, h in ipairs(Poker.HAND_TYPES_ORDERED) do
        local cy = rowY + (idx - 1) * (rowH + rowGap)
        local isUnlocked = (game.unlockedHands[h.id] == true)

        -- Row Container
        if isUnlocked then
            love.graphics.setColor(0.12, 0.17, 0.22, 0.95)
            UI.drawRoundedRect("fill", modalX + 25, cy, modalW - 50, rowH, 8)
            love.graphics.setLineWidth(1.5)
            love.graphics.setColor(0.25, 0.65, 0.45, 0.8)
            UI.drawRoundedRect("line", modalX + 25, cy, modalW - 50, rowH, 8)
        else
            love.graphics.setColor(0.10, 0.11, 0.14, 0.8)
            UI.drawRoundedRect("fill", modalX + 25, cy, modalW - 50, rowH, 8)
            love.graphics.setLineWidth(1)
            love.graphics.setColor(0.25, 0.28, 0.35, 0.4)
            UI.drawRoundedRect("line", modalX + 25, cy, modalW - 50, rowH, 8)
        end

        -- Status Badge (Left)
        local badgeW = 125
        local badgeH = 30
        local badgeX = modalX + 38
        local badgeY = cy + (rowH - badgeH) / 2
        if isUnlocked then
            love.graphics.setColor(0.15, 0.45, 0.25, 0.9)
            UI.drawRoundedRect("fill", badgeX, badgeY, badgeW, badgeH, 6)
            love.graphics.setFont(UI.fonts.small)
            love.graphics.setColor(0.3, 1.0, 0.5, 1)
            love.graphics.printf("ĐÃ MỞ KHÓA", badgeX, badgeY + 5, badgeW, "center")
        else
            love.graphics.setColor(0.35, 0.15, 0.15, 0.85)
            UI.drawRoundedRect("fill", badgeX, badgeY, badgeW, badgeH, 6)
            love.graphics.setFont(UI.fonts.small)
            love.graphics.setColor(0.95, 0.4, 0.4, 1)
            love.graphics.printf("ĐANG KHÓA", badgeX, badgeY + 5, badgeW, "center")
        end

        -- Hand Title & Requirements
        local textX = badgeX + badgeW + 16
        love.graphics.setFont(UI.fonts.regular)
        love.graphics.setColor(isUnlocked and UI.COLORS.goldYellow or { 0.6, 0.65, 0.7, 0.7 })
        love.graphics.print(h.vnName .. " (" .. h.name .. ")", textX, cy + 6)

        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(isUnlocked and UI.COLORS.textLight or UI.COLORS.textMuted)
        local reqStr = handDescriptions[h.id] or (h.subtitle .. " (" .. h.requiredCards .. " lá)")
        love.graphics.print(reqStr, textX, cy + 32)

        -- Base Stats (Right)
        local statsW = 200
        local statsX = modalX + modalW - 25 - statsW - 15
        love.graphics.setColor(0.07, 0.08, 0.11, 0.8)
        UI.drawRoundedRect("fill", statsX, cy + 8, statsW, rowH - 16, 6)

        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(UI.COLORS.chipsBlue)
        love.graphics.print(h.baseChips .. " Chips", statsX + 14, cy + 18)
        love.graphics.setColor(UI.COLORS.textLight)
        love.graphics.print(" × ", statsX + 92, cy + 18)
        love.graphics.setColor(UI.COLORS.multRed)
        love.graphics.print(h.baseMult .. " Mult", statsX + 116, cy + 18)
    end
end

local function drawShopState()
    local winW, winH = love.graphics.getDimensions()
    love.graphics.setColor(0.10, 0.12, 0.14, 1)
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)

    local mx, my = toVirtual(love.mouse.getPosition())

    love.graphics.setFont(UI.fonts.large)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf("CỬA HÀNG LỮ KHÁCH (VÙNG ĐẤT " .. game.act .. " - TẦNG " .. (game.map and game.map.currentFloor or 1) .. ")", 0, 20, V_WIDTH, "center")

    love.graphics.setFont(UI.fonts.regular)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Tiền hiện có: $" .. game.gold .. "   |   Mua Sách Bí Tịch để mở khóa bài đánh (Đôi, Sảnh, Thùng...) hoặc Vũ Khí/Trang Bị!", 0, 60, V_WIDTH, "center")

    ----------------------------------------------------------------------------
    -- Shop Items For Sale
    ----------------------------------------------------------------------------
    love.graphics.setFont(UI.fonts.regular)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.print("VẬT PHẨM & BÍ TỊCH ĐANG BÁN:", 80, 105)

    buttons = {}
    local itemCount = #shopData.items
    local itemW = 340
    local itemH = 250
    local gap = 30
    if itemCount >= 5 then
        itemW = 216
        gap = 14
    elseif itemCount == 4 then
        itemW = 265
        gap = 18
    end
    local totalW = itemCount * itemW + math.max(0, itemCount - 1) * gap
    local startX = (V_WIDTH - totalW) / 2
    local itemY = 140

    for i, item in ipairs(shopData.items) do
        local ix = startX + (i - 1) * (itemW + gap)
        local isHovered = (mx >= ix and mx <= ix + itemW and my >= itemY and my <= itemY + itemH)

        love.graphics.setColor(0.16, 0.20, 0.24, 1)
        UI.drawRoundedRect("fill", ix, itemY, itemW, itemH, 10)

        local borderCol = item.color or { 0.35, 0.45, 0.55, 1 }
        love.graphics.setLineWidth(isHovered and 3 or 1.5)
        love.graphics.setColor(borderCol)
        UI.drawRoundedRect("line", ix, itemY, itemW, itemH, 10)

        -- Icon & Subtitle Badge
        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(borderCol)
        love.graphics.printf("[" .. (item.subtitle or "VẬT PHẨM") .. "]", ix, itemY + 12, itemW, "center")

        -- Item Name
        love.graphics.setFont(UI.fonts.medium)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(item.name, ix + 8, itemY + 38, itemW - 16, "center")

        -- Description
        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(UI.COLORS.textLight)
        love.graphics.printf(item.desc, ix + 12, itemY + 80, itemW - 24, "center")

        -- Buy Button
        local canAfford = (game.gold >= item.cost)
        local btnBuy = {
            id = "buy_" .. i,
            text = "MUA: $" .. item.cost,
            x = ix + 30,
            y = itemY + itemH - 52,
            w = itemW - 60,
            h = 40,
            color = canAfford and UI.COLORS.btnPlay or UI.COLORS.btnNormal,
            font = UI.fonts.regular,
            disabled = not canAfford,
            itemIndex = i,
        }
        table.insert(buttons, btnBuy)
        UI.drawButton(btnBuy, mx >= btnBuy.x and mx <= btnBuy.x + btnBuy.w and my >= btnBuy.y and my <= btnBuy.y + btnBuy.h)
    end

    ----------------------------------------------------------------------------
    -- Equipped Deities & Sell Option
    ----------------------------------------------------------------------------
    love.graphics.setFont(UI.fonts.regular)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.print("THẦN BÀI ĐANG TRANG BỊ (" .. #game.deities .. "/5) — Nhấp [Bán] để dọn chỗ:", 80, 405)

    local ownedW = 210
    local ownedH = 120
    local ownedStartX = 80
    local ownedY = 440

    for i = 1, 5 do
        local ox = ownedStartX + (i - 1) * (ownedW + 15)
        local d = game.deities[i]
        if d then
            love.graphics.setColor(0.18, 0.22, 0.26, 1)
            UI.drawRoundedRect("fill", ox, ownedY, ownedW, ownedH, 8)
            love.graphics.setColor(0.35, 0.45, 0.55, 1)
            UI.drawRoundedRect("line", ox, ownedY, ownedW, ownedH, 8)

            love.graphics.setFont(UI.fonts.small)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf(d.name, ox, ownedY + 8, ownedW, "center")

            love.graphics.setFont(UI.fonts.tiny)
            love.graphics.setColor(UI.COLORS.textMuted)
            love.graphics.printf(d.desc, ox + 6, ownedY + 30, ownedW - 12, "center")

            local sellPrice = math.max(1, math.floor((d.cost or 4) / 2))
            local btnSell = {
                id = "sell_" .. i,
                text = "Bán (+$" .. sellPrice .. ")",
                x = ox + 35,
                y = ownedY + ownedH - 32,
                w = ownedW - 70,
                h = 24,
                color = UI.COLORS.btnDiscard,
                font = UI.fonts.tiny,
                deityIndex = i,
            }
            table.insert(buttons, btnSell)
            UI.drawButton(btnSell, mx >= btnSell.x and mx <= btnSell.x + btnSell.w and my >= btnSell.y and my <= btnSell.y + btnSell.h)
        else
            love.graphics.setColor(0.14, 0.16, 0.18, 0.6)
            UI.drawRoundedRect("fill", ox, ownedY, ownedW, ownedH, 8)
            love.graphics.setColor(0.25, 0.3, 0.35, 0.5)
            UI.drawRoundedRect("line", ox, ownedY, ownedW, ownedH, 8)
            love.graphics.setFont(UI.fonts.small)
            love.graphics.setColor(0.4, 0.45, 0.5, 0.7)
            love.graphics.printf("Ô Trống " .. i, ox, ownedY + 45, ownedW, "center")
        end
    end

    ----------------------------------------------------------------------------
    -- Bottom Control Buttons
    ----------------------------------------------------------------------------
    local btnReroll = {
        id = "reroll",
        text = "LÀM MỚI ($" .. shopData.rerollCost .. ")",
        x = 40,
        y = 605,
        w = 190,
        h = 50,
        color = (game.gold >= shopData.rerollCost) and { 0.25, 0.45, 0.65, 1 } or UI.COLORS.btnNormal,
        font = UI.fonts.regular,
        disabled = (game.gold < shopData.rerollCost),
    }
    table.insert(buttons, btnReroll)
    UI.drawButton(btnReroll, mx >= btnReroll.x and mx <= btnReroll.x + btnReroll.w and my >= btnReroll.y and my <= btnReroll.y + btnReroll.h)

    local btnTransfer = {
        id = "open_shop_transfer",
        text = "HOÁN ĐỔI TRANG BỊ",
        x = 260,
        y = 605,
        w = 210,
        h = 50,
        color = { 0.52, 0.26, 0.72, 1 },
        font = UI.fonts.regular,
    }
    table.insert(buttons, btnTransfer)
    UI.drawButton(btnTransfer, mx >= btnTransfer.x and mx <= btnTransfer.x + btnTransfer.w and my >= btnTransfer.y and my <= btnTransfer.y + btnTransfer.h)

    local btnDeckShop = {
        id = "open_deck_viewer",
        text = "BỘ BÀI [Tab]",
        x = 490,
        y = 605,
        w = 180,
        h = 50,
        color = { 0.20, 0.38, 0.58, 1 },
        font = UI.fonts.regular,
    }
    table.insert(buttons, btnDeckShop)
    UI.drawButton(btnDeckShop, mx >= btnDeckShop.x and mx <= btnDeckShop.x + btnDeckShop.w and my >= btnDeckShop.y and my <= btnDeckShop.y + btnDeckShop.h)

    local btnHandbookShop = {
        id = "open_handbook",
        text = "SỔ TAY [H]",
        x = 690,
        y = 605,
        w = 170,
        h = 50,
        color = { 0.22, 0.45, 0.35, 1 },
        font = UI.fonts.regular,
    }
    table.insert(buttons, btnHandbookShop)
    UI.drawButton(btnHandbookShop, mx >= btnHandbookShop.x and mx <= btnHandbookShop.x + btnHandbookShop.w and my >= btnHandbookShop.y and my <= btnHandbookShop.y + btnHandbookShop.h)

    local btnLeaveShop = {
        id = "leave_shop",
        text = "RỜI SHOP (VỀ BẢN ĐỒ) ->",
        x = 880,
        y = 605,
        w = 340,
        h = 50,
        color = UI.COLORS.btnPlay,
        font = UI.fonts.regular,
    }
    table.insert(buttons, btnLeaveShop)
    UI.drawButton(btnLeaveShop, mx >= btnLeaveShop.x and mx <= btnLeaveShop.x + btnLeaveShop.w and my >= btnLeaveShop.y and my <= btnLeaveShop.y + btnLeaveShop.h)

    if isShopTransferOpen then
        drawShopTransferView()
    end
end

local function drawGameOverState()
    local winW, winH = love.graphics.getDimensions()
    love.graphics.setColor(0.08, 0.05, 0.05, 1)
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)

    local mx, my = toVirtual(love.mouse.getPosition())

    love.graphics.setFont(UI.fonts.huge)
    love.graphics.setColor(UI.COLORS.multRed)
    love.graphics.printf("BẠN ĐÃ BỊ ĐÁNH BẠI!", 0, 160, V_WIDTH, "center")

    love.graphics.setFont(UI.fonts.large)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Dừng bước tại Round " .. game.round .. " trước " .. (game.monster and game.monster.name or "Quái Vật"), 0, 240, V_WIDTH, "center")

    love.graphics.setFont(UI.fonts.medium)
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.printf("Máu quái còn lại: " .. (game.monster and game.monster.hp or 0) .. " HP", 0, 290, V_WIDTH, "center")

    buttons = {}
    local btnRetry = {
        id = "retry",
        text = "CHƠI LẠI TỪ ĐẦU",
        x = (V_WIDTH - 260) / 2,
        y = 380,
        w = 260,
        h = 60,
        color = UI.COLORS.btnPlay,
        font = UI.fonts.medium,
    }
    table.insert(buttons, btnRetry)
    UI.drawButton(btnRetry, mx >= btnRetry.x and mx <= btnRetry.x + btnRetry.w and my >= btnRetry.y and my <= btnRetry.y + btnRetry.h)
end

function love.draw()
    love.graphics.push()
    love.graphics.translate(offsetX, offsetY)
    love.graphics.scale(scale, scale)

    if screenShake > 0 then
        local sx = (love.math.random() * 2 - 1) * screenShake
        local sy = (love.math.random() * 2 - 1) * screenShake
        love.graphics.translate(sx, sy)
    end

    if state == "menu" then
        drawMenu()
    elseif state == "map" then
        drawMap()
    elseif state == "playing" then
        drawPlayingState()
    elseif state == "scoring" then
        drawScoringState()
    elseif state == "event" then
        drawEventState()
    elseif state == "boss_deity" then
        drawBossDeityDraftState()
    elseif state == "chest" then
        drawChestState()
    elseif state == "socketing" then
        drawSocketingView()
    elseif state == "shop" then
        drawShopState()
    elseif state == "rest" then
        drawRestState()
    elseif state == "treasure" then
        drawTreasureState()
    elseif state == "gameover" then
        drawGameOverState()
    end

    if isDeckViewerOpen then
        drawDeckViewerModal()
    end

    if isHandbookOpen then
        drawHandbookModal()
    end

    if inspectCardModal then
        drawCardInspectorModal(inspectCardModal)
    end

    love.graphics.pop()
end

--------------------------------------------------------------------------------
-- INPUT HANDLING
--------------------------------------------------------------------------------

function love.mousepressed(x, y, button)
    local mx, my = toVirtual(x, y)

    -- 0. Handbook Modal Dismissal
    if isHandbookOpen then
        if button == 1 then
            for _, btn in ipairs(buttons) do
                if btn.id == "close_handbook" and mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                    isHandbookOpen = false
                    Sound.play("card_deal")
                    return
                end
            end
            local modalW = 960
            local modalH = 650
            local modalX = (V_WIDTH - modalW) / 2
            local modalY = (V_HEIGHT - modalH) / 2
            if mx < modalX or mx > modalX + modalW or my < modalY or my > modalY + modalH then
                isHandbookOpen = false
                Sound.play("card_deal")
                return
            end
            return
        end
    end

    -- 1. Right-Click Inspector Modal Dismissal
    if inspectCardModal then
        if button == 2 then
            inspectCardModal = nil
            Sound.play("card_deal")
            return
        elseif button == 1 then
            for _, btn in ipairs(buttons) do
                if btn.id == "close_inspector" and mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                    inspectCardModal = nil
                    Sound.play("card_deal")
                    return
                end
            end
            local modalW = 860
            local modalH = 540
            local modalX = (V_WIDTH - modalW) / 2
            local modalY = (V_HEIGHT - modalH) / 2
            if mx < modalX or mx > modalX + modalW or my < modalY or my > modalY + modalH then
                inspectCardModal = nil
                Sound.play("card_deal")
                return
            end
            return
        end
    end

    -- 2. Right-Click (button == 2) on any card opens Card Inspector Modal
    if button == 2 then
        -- In Deck Viewer Modal
        if isDeckViewerOpen then
            local modalW = 1180
            local modalH = 650
            local modalX = (V_WIDTH - modalW) / 2
            local modalY = (V_HEIGHT - modalH) / 2
            local cardGridX = modalX + 24
            local cardGridY = modalY + 128
            local cw = 74
            local ch = 108
            local cgap = 10
            local cols = 8

            local allCards = {}
            for _, c in ipairs(game.deck) do table.insert(allCards, c) end
            for _, c in ipairs(game.hand) do table.insert(allCards, c) end
            for _, c in ipairs(game.discardPile) do table.insert(allCards, c) end

            local filteredCards = {}
            for _, c in ipairs(allCards) do
                local hasEq = (c.equipments and #c.equipments > 0)
                if deckViewerFilter == "all" then
                    table.insert(filteredCards, c)
                elseif deckViewerFilter == "equipped" and hasEq then
                    table.insert(filteredCards, c)
                elseif deckViewerFilter == c.suit then
                    table.insert(filteredCards, c)
                end
            end

            for i, c in ipairs(filteredCards) do
                local col = (i - 1) % cols
                local row = math.floor((i - 1) / cols)
                local cx = cardGridX + col * (cw + cgap)
                local cy = cardGridY + row * (ch + cgap)
                if cy + ch <= modalY + modalH - 20 then
                    if mx >= cx and mx <= cx + cw and my >= cy and my <= cy + ch then
                        inspectCardModal = c
                        Sound.play("card_deal")
                        return
                    end
                end
            end
        end

        -- In playing or other states: check hand cards
        if #game.hand > 0 then
            for i = #game.hand, 1, -1 do
                local c = game.hand[i]
                local cx, cy, cardW, cardH = getHandCardPosition(i, #game.hand)
                if c.selected then cy = cy - 26 end

                if mx >= cx and mx <= cx + cardW and my >= cy and my <= cy + cardH then
                    inspectCardModal = c
                    Sound.play("card_deal")
                    return
                end
            end
        end

        return
    end

    if button ~= 1 then return end

    -- Intercept all clicks when Deck Viewer Modal is open
    if isDeckViewerOpen then
        local modalW = 1180
        local modalH = 650
        local modalX = (V_WIDTH - modalW) / 2
        local modalY = (V_HEIGHT - modalH) / 2

        -- Close button
        local closeX = modalX + modalW - 160
        local closeY = modalY + 15
        if mx >= closeX and mx <= closeX + 140 and my >= closeY and my <= closeY + 38 then
            isDeckViewerOpen = false
            Sound.play("card_deal")
            return
        end

        -- Filter tabs
        local tabStartX = modalX + 24
        local tabY = modalY + 86
        local tabW = 108
        local tabH = 30
        local filterIds = { "all", "aurelia", "elaris", "vharos", "valoria", "equipped" }
        for idx, fid in ipairs(filterIds) do
            local tx = tabStartX + (idx - 1) * (tabW + 6)
            if mx >= tx and mx <= tx + tabW and my >= tabY and my <= tabY + tabH then
                deckViewerFilter = fid
                Sound.play("card_deal")
                return
            end
        end

        -- Click outside modal closes it
        if mx < modalX or mx > modalX + modalW or my < modalY or my > modalY + modalH then
            isDeckViewerOpen = false
            Sound.play("card_deal")
            return
        end

        return
    end

    if state == "menu" then
        local cardW = 240
        local cardH = 370
        local startX = (V_WIDTH - (4 * cardW + 3 * 24)) / 2
        local cardY = 140
        local factionKeys = { "aurelia", "elaris", "vharos", "valoria" }

        for i, fkey in ipairs(factionKeys) do
            local cx = startX + (i - 1) * (cardW + 24)
            if mx >= cx and mx <= cx + cardW and my >= cardY and my <= cardY + cardH then
                startNewGame(fkey)
                return
            end
        end

    elseif state == "map" then
        for _, btn in ipairs(buttons) do
            if mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                if btn.id == "open_handbook" then
                    isHandbookOpen = true
                    Sound.play("card_deal")
                    return
                elseif btn.id == "open_deck_viewer" then
                    isDeckViewerOpen = true
                    Sound.play("card_deal")
                    return
                elseif btn.id == "map_scroll_start" then
                    if game.map then Map.scroll(game.map, -9999) end
                    Sound.play("card_deal")
                    return
                elseif btn.id == "map_scroll_focus" then
                    if game.map then Map.focusFloor(game.map, game.map.currentFloor) end
                    Sound.play("card_deal")
                    return
                elseif btn.id == "map_scroll_end" then
                    if game.map then Map.scroll(game.map, 9999) end
                    Sound.play("card_deal")
                    return
                end
            end
        end

        local clickedNode = Map.getNodeAt(game.map, mx, my)
        if clickedNode and clickedNode.available then
            game.currentNodeId = clickedNode.id
            if clickedNode.type == "monster" then
                startMonsterEncounter(clickedNode.floor, false, false)
                state = "playing"
                Sound.play("card_deal")
            elseif clickedNode.type == "elite" then
                startMonsterEncounter(clickedNode.floor, false, true)
                state = "playing"
                Sound.play("card_deal")
            elseif clickedNode.type == "boss" then
                startMonsterEncounter(clickedNode.floor, true, false)
                state = "playing"
                Sound.play("round_win")
            elseif clickedNode.type == "shop" then
                Shop.refresh(shopData, game)
                state = "shop"
                Sound.play("card_deal")
            elseif clickedNode.type == "event" then
                game.currentEvent = Events.getRandomEvent(game)
                game.eventOutcomeText = nil
                state = "event"
                Sound.play("card_deal")
            elseif clickedNode.type == "rest" then
                restStateData = { chosenAction = nil, selectedCard = nil, message = nil }
                state = "rest"
                Sound.play("card_deal")
            elseif clickedNode.type == "treasure" then
                generateTreasureRewards()
                state = "treasure"
                Sound.play("card_deal")
            end
            return
        end

    elseif state == "playing" then
        for _, btn in ipairs(buttons) do
            if not btn.disabled and mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                if btn.id == "play" then
                    playSelectedHand()
                    return
                elseif btn.id == "discard" then
                    discardSelected()
                    return
                elseif btn.id == "sort_rank" then
                    game.sortMode = "rank"
                    Deck.sortByRank(game.hand)
                    clearAllSelections()
                    syncCardSelections()
                    Sound.play("card_deal")
                    return
                elseif btn.id == "sort_suit" then
                    game.sortMode = "suit"
                    Deck.sortBySuit(game.hand)
                    clearAllSelections()
                    syncCardSelections()
                    Sound.play("card_deal")
                    return
                elseif btn.id == "open_handbook" then
                    isHandbookOpen = true
                    Sound.play("card_deal")
                    return
                elseif btn.id == "open_deck_viewer" then
                    isDeckViewerOpen = true
                    Sound.play("card_deal")
                    return
                end
            end
        end

        for i = #game.hand, 1, -1 do
            local c = game.hand[i]
            local cx, cy, cardW, cardH = getHandCardPosition(i, #game.hand)
            if c.selected then cy = cy - 26 end

            if mx >= cx and mx <= cx + cardW and my >= cy and my <= cy + cardH then
                toggleCardSelection(i)
                return
            end
        end

    elseif state == "scoring" then
        -- Fast-forward scoring step on click
        anim.stepTimer = 999
        return

    elseif state == "event" then
        for _, btn in ipairs(buttons) do
            if mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                if btn.id == "event_continue" then
                    if game.currentNodeId and game.map then
                        Map.onNodeCompleted(game.map, game.currentNodeId)
                    end
                    game.currentEvent = nil
                    game.eventOutcomeText = nil
                    state = "map"
                    Sound.play("card_deal")
                    return
                elseif btn.id:sub(1, 10) == "event_opt_" then
                    local optIndex = btn.optIndex
                    local evt = game.currentEvent
                    if evt and evt.options and evt.options[optIndex] then
                        local opt = evt.options[optIndex]
                        local msg, eq = opt.action(game)
                        if eq then
                            pendingEquipment = eq
                            socketingReturnState = "map"
                            if game.currentNodeId and game.map then
                                Map.onNodeCompleted(game.map, game.currentNodeId)
                            end
                            game.currentEvent = nil
                            game.eventOutcomeText = nil
                            state = "socketing"
                        else
                            game.eventOutcomeText = msg
                            Sound.play("round_win")
                        end
                        return
                    end
                end
            end
        end

    elseif state == "boss_deity" then
        for _, btn in ipairs(buttons) do
            if mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                if btn.id:sub(1, 11) == "boss_deity_" then
                    local chosen = game.bossDeityDraft[btn.deityIndex]
                    if chosen then
                        Deities.addDeity(game, chosen)
                        Sound.play("round_win")
                        generateBossChestRewards()
                        socketingReturnState = "next_act"
                        state = "chest"
                        return
                    end
                end
            end
        end

    elseif state == "chest" then
        for _, btn in ipairs(buttons) do
            if mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                local rew = chestRewards[btn.rewardIndex]
                if rew then
                    if rew.type == "card" then
                        Deck.addCardToDeck(game, rew.card)
                        Sound.play("card_deal")
                        if socketingReturnState == "next_act" then
                            if game.currentNodeId and game.map then
                                Map.onNodeCompleted(game.map, game.currentNodeId)
                            end
                            game.act = game.act + 1
                            game.map = Map.generate(game.act)
                            game.currentNodeId = nil
                            state = "map"
                        else
                            state = "map"
                        end
                    elseif rew.type == "equipment" then
                        pendingEquipment = rew.item
                        state = "socketing"
                    end
                    return
                end
            end
        end

    elseif state == "treasure" then
        for _, btn in ipairs(buttons) do
            if mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                local rew = treasureRewards[btn.rewardIndex]
                if rew then
                    if rew.type == "card" then
                        Deck.addCardToDeck(game, rew.card)
                        Sound.play("card_deal")
                        if game.currentNodeId and game.map then
                            Map.onNodeCompleted(game.map, game.currentNodeId)
                        end
                        state = "map"
                    elseif rew.type == "equipment" then
                        pendingEquipment = rew.item
                        socketingReturnState = "map"
                        state = "socketing"
                    end
                    return
                end
            end
        end

    elseif state == "rest" then
        for _, btn in ipairs(buttons) do
            if mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                if btn.id == "rest_action_heal" then
                    game.maxHands = game.maxHands + 1
                    game.maxDiscards = game.maxDiscards + 1
                    game.handsRemaining = game.maxHands
                    game.discardsRemaining = game.maxDiscards
                    restStateData.chosenAction = "rest"
                    restStateData.message = "Đã Dưỡng Sức thành công! Giới hạn tăng lên: " .. game.maxHands .. " Lượt Đánh & " .. game.maxDiscards .. " Lượt Đổi bài!"
                    Sound.play("round_win")
                    return
                elseif btn.id == "rest_action_forge" then
                    restStateData.chosenAction = "forge"
                    Sound.play("card_deal")
                    return
                elseif btn.id == "leave_rest" then
                    if game.currentNodeId and game.map then
                        Map.onNodeCompleted(game.map, game.currentNodeId)
                    end
                    state = "map"
                    Sound.play("card_deal")
                    return
                end
            end
        end

        -- If choosing card to forge
        if restStateData.chosenAction == "forge" and not restStateData.selectedCard then
            local allCards = getAllDeckCards()
            for i, c in ipairs(allCards) do
                local cx, cy, cw, ch = getCardGridPos(i, #allCards, 100, 145, 16, 32, 8, 250)
                if mx >= cx and mx <= cx + cw and my >= cy and my <= cy + ch then
                    Deck.upgradeCard(c)
                    restStateData.selectedCard = c
                    restStateData.message = "Đã tôi luyện thành công lá " .. c.suitSymbol .. " lên Rank " .. c.rankName .. " (+1 Rank vĩnh viễn, bền " .. c.rank .. " lần đánh)!"
                    Sound.play("round_win")
                    return
                end
            end
        end

    elseif state == "socketing" then
        for _, btn in ipairs(buttons) do
            if mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                if btn.id == "skip_socket" then
                    pendingEquipment = nil
                    if socketingReturnState == "next_act" then
                        if game.currentNodeId and game.map then
                            Map.onNodeCompleted(game.map, game.currentNodeId)
                        end
                        game.act = game.act + 1
                        game.map = Map.generate(game.act)
                        game.currentNodeId = nil
                        state = "map"
                    elseif socketingReturnState == "shop" then
                        state = "shop"
                    elseif socketingReturnState == "map" then
                        if game.currentNodeId and game.map then
                            Map.onNodeCompleted(game.map, game.currentNodeId)
                        end
                        state = "map"
                    else
                        state = "map"
                    end
                    return
                end
            end
        end

        -- Check which card is clicked to attach equipment
        local allCards = getAllDeckCards()
        for i, c in ipairs(allCards) do
            local cx, cy, cardW, cardH = getCardGridPos(i, #allCards, 100, 145, 16, 32, 8, 240)
            if mx >= cx and mx <= cx + cardW and my >= cy and my <= cy + cardH then
                local success, msg = Equipment.attach(c, pendingEquipment)
                if success then
                    -- Sync equipment to persistentDeck if c is not already pc
                    if game.persistentDeck then
                        for _, pc in ipairs(game.persistentDeck) do
                            if pc.id == c.id and pc ~= c then
                                pc.equipments = {}
                                for _, eq in ipairs(c.equipments) do
                                    table.insert(pc.equipments, eq)
                                end
                                break
                            end
                        end
                    end
                    Sound.play("chip_tick")
                    pendingEquipment = nil
                    if socketingReturnState == "next_act" then
                        if game.currentNodeId and game.map then
                            Map.onNodeCompleted(game.map, game.currentNodeId)
                        end
                        game.act = game.act + 1
                        game.map = Map.generate(game.act)
                        game.currentNodeId = nil
                        state = "map"
                    elseif socketingReturnState == "shop" then
                        state = "shop"
                    elseif socketingReturnState == "map" then
                        if game.currentNodeId and game.map then
                            Map.onNodeCompleted(game.map, game.currentNodeId)
                        end
                        state = "map"
                    else
                        state = "map"
                    end
                    return
                else
                    Sound.play("card_deselect")
                    table.insert(anim.floatingTexts, {
                        text = msg or "Không thể gắn trang bị!",
                        color = UI.COLORS.multRed,
                        x = 640,
                        y = 400,
                        alpha = 2.0,
                    })
                end
            end
        end

    elseif state == "shop" then
        if isShopTransferOpen then
            for _, btn in ipairs(buttons) do
                if mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                    if btn.id == "close_shop_transfer" then
                        isShopTransferOpen = false
                        transferSourceCard = nil
                        transferSourceEqIndex = nil
                        transferMessage = nil
                        Sound.play("card_deal")
                        return
                    end
                end
            end

            local allCards = getAllDeckCards()

            local cw = 90
            local ch = 130
            local gap = 18
            local totalW = #allCards * cw + math.max(0, #allCards - 1) * gap
            local startX = math.max(80, (V_WIDTH - totalW) / 2)
            local cardY = 125

            -- Step 1 click: source card
            for i, c in ipairs(allCards) do
                local cx = startX + (i - 1) * (cw + gap)
                if mx >= cx and mx <= cx + cw and my >= cardY and my <= cardY + ch then
                    transferSourceCard = c
                    transferSourceEqIndex = nil
                    transferMessage = nil
                    Sound.play("card_select")
                    return
                end
            end

            -- Step 2 click: equipment slot
            if transferSourceCard and transferSourceCard.equipments then
                local eqBoxW = 210
                local eqBoxH = 65
                for idx, eq in ipairs(transferSourceCard.equipments) do
                    local ex = 80 + (idx - 1) * (eqBoxW + 16)
                    local ey = 320
                    if mx >= ex and mx <= ex + eqBoxW and my >= ey and my <= ey + eqBoxH then
                        transferSourceEqIndex = idx
                        transferMessage = nil
                        Sound.play("card_select")
                        return
                    end
                end
            end

            -- Step 3 click: target card
            if transferSourceCard and transferSourceEqIndex and transferSourceCard.equipments and transferSourceCard.equipments[transferSourceEqIndex] then
                local targetY = 445
                for i, c in ipairs(allCards) do
                    local cx = startX + (i - 1) * (cw + gap)
                    if c ~= transferSourceCard and (not c.equipments or #c.equipments < 5) and mx >= cx and mx <= cx + cw and my >= targetY and my <= targetY + ch then
                        local ok, msg = Shop.transferEquipment(transferSourceCard, transferSourceEqIndex, c)
                        transferMessage = msg
                        if ok then
                            transferSourceEqIndex = nil
                        end
                        return
                    end
                end
            end

            return
        end

        for _, btn in ipairs(buttons) do
            if not btn.disabled and mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                if btn.id:sub(1, 4) == "buy_" then
                    local success, msg, eq = Shop.buyItem(shopData, btn.itemIndex, game)
                    if success and eq then
                        pendingEquipment = eq
                        socketingReturnState = "shop"
                        state = "socketing"
                    end
                    return
                elseif btn.id:sub(1, 5) == "sell_" then
                    Shop.sellDeity(game, btn.deityIndex)
                    return
                elseif btn.id == "reroll" then
                    Shop.reroll(shopData, game)
                    return
                elseif btn.id == "open_shop_transfer" then
                    isShopTransferOpen = true
                    transferSourceCard = nil
                    transferSourceEqIndex = nil
                    transferMessage = nil
                    Sound.play("card_deal")
                    return
                elseif btn.id == "open_handbook" then
                    isHandbookOpen = true
                    Sound.play("card_deal")
                    return
                elseif btn.id == "open_deck_viewer" then
                    isDeckViewerOpen = true
                    Sound.play("card_deal")
                    return
                elseif btn.id == "leave_shop" or btn.id == "next_round" then
                    if game.currentNodeId and game.map then
                        Map.onNodeCompleted(game.map, game.currentNodeId)
                    end
                    state = "map"
                    Sound.play("card_deal")
                    return
                end
            end
        end

    elseif state == "gameover" then
        for _, btn in ipairs(buttons) do
            if mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                if btn.id == "retry" then
                    state = "menu"
                    return
                end
            end
        end
    end
end

function love.keypressed(key)
    -- Global Fullscreen Toggle
    if key == "f11" then
        love.window.setFullscreen(not love.window.getFullscreen())
        updateScale()
        return
    end

    -- Toggle Deck Viewer Modal
    if key == "tab" or key == "b" then
        isDeckViewerOpen = not isDeckViewerOpen
        Sound.play("card_deal")
        return
    end

    -- Toggle Handbook Modal
    if key == "h" then
        isHandbookOpen = not isHandbookOpen
        Sound.play("card_deal")
        return
    end

    -- Escape closes Inspector, Handbook, Shop Transfer or Deck Viewer
    if key == "escape" then
        if inspectCardModal then
            inspectCardModal = nil
            Sound.play("card_deal")
            return
        end
        if isHandbookOpen then
            isHandbookOpen = false
            Sound.play("card_deal")
            return
        end
        if isShopTransferOpen then
            isShopTransferOpen = false
            Sound.play("card_deal")
            return
        end
        if isDeckViewerOpen then
            isDeckViewerOpen = false
            Sound.play("card_deal")
            return
        end
    end

    if state == "playing" then
        if key == "space" or key == "return" then
            playSelectedHand()
        elseif key == "d" then
            discardSelected()
        elseif key == "r" then
            game.sortMode = "rank"
            Deck.sortByRank(game.hand)
            clearAllSelections()
            syncCardSelections()
            Sound.play("card_deal")
        elseif key == "s" then
            game.sortMode = "suit"
            Deck.sortBySuit(game.hand)
            clearAllSelections()
            syncCardSelections()
            Sound.play("card_deal")
        elseif key >= "1" and key <= "8" then
            local idx = tonumber(key)
            if idx and idx <= #game.hand then
                toggleCardSelection(idx)
            end
        end
    elseif state == "scoring" then
        if key == "space" or key == "return" then
            anim.stepTimer = 999
        end
    end
end

function love.wheelmoved(x, y)
    if state == "map" and game.map then
        Map.scroll(game.map, -y * 120)
    end
end
