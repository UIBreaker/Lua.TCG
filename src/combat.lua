local Deck = require("src.deck")
local Deities = require("src.deities")

local Combat = {}

local function isFaction(game, id)
    return game.selectedFaction == id or game.selectedSuit == id
end

function Combat.start(game, monster, round)
    assert(game and monster, "Combat.start requires game state and monster")
    game.round = round or 1
    game.monster = monster
    game.handsRemaining = game.maxHands
    game.playerArmor = 0
    game.playerShield = 0
    game.discardsUsedInCombat = 0
    game.discardsRemaining = isFaction(game, "valoria") and (game.maxDiscards + 1) or game.maxDiscards
    game.martyrStacks = 0
    game.jHeartDiscardUsed = false
    game.playedHandsHistory = {}
    game.handsPlayedThisCombat = 0
    game.selectedIndices = {}
    game.discardBuffs = { chips = 0, mult = 0, xMult = 1.0, bonusDamagePct = 0 }

    -- Boss modifiers and deity round-start effects are intentionally combat
    -- scoped. Persistent limits such as maxHands/maxDiscards are never reset.
    if monster.isBoss and monster.bossData and monster.bossData.applyModifier then
        monster.bossData.applyModifier(game)
    end
    local maxSlots = Deities.getMaxSlots(game)
    for slot = 1, maxSlots do
        local deity = game.deities and game.deities[slot]
        if deity and deity.onRoundStart then
            local result = deity.onRoundStart(game)
            game.discardsRemaining = game.discardsRemaining + (result and result.addDiscards or 0)
            game.handsRemaining = game.handsRemaining + (result and result.addHands or 0)
        end
    end

    local slaughterChips = game.storedSlaughterChips or 0
    if slaughterChips > 0 then
        game.discardBuffs.chips = slaughterChips
        game.storedSlaughterChips = 0
    end

    if not game.persistentDeck or #game.persistentDeck == 0 then
        game.persistentDeck = Deck.createStarterDeck(game.selectedFaction or game.selectedSuit or "aurelia")
    end
    Deck.restoreDeck(game.persistentDeck)
    game.masterDeck = game.persistentDeck
    game.deck = {}
    for _, card in ipairs(game.persistentDeck) do
        table.insert(game.deck, Deck.cloneCard(card))
    end
    game.discardPile = {}
    game.hand = {}
    Deck.shuffle(game.deck)

    local maxHandSize = isFaction(game, "elaris") and ((game.maxHandSize or 3) + 1) or (game.maxHandSize or 3)
    while #game.hand < maxHandSize and #game.deck > 0 do
        local card = table.remove(game.deck)
        card.selected = false
        card.visualX = 1180
        card.visualY = 620
        card.visualAngle = 0
        card.visualScale = 0.7
        local isAxiomCard = not card.disableFactionPassives and (card.suit == "spades" or card.suit == "vharos" or card.suit == "iron_axiom")
        local bossData = monster.bossData
        if not isAxiomCard and monster.isBoss and bossData and (bossData.id == "the_fish" or bossData.debuffId == "the_fish") then
            card.faceDown = true
        end
        table.insert(game.hand, card)
    end

    if isFaction(game, "vharos") or isFaction(game, "spades") or isFaction(game, "iron_axiom") or game.sortMode == "rank" then
        Deck.sortByRank(game.hand)
    else
        Deck.sortBySuit(game.hand)
    end
    return { slaughterChips = slaughterChips }
end

return Combat
