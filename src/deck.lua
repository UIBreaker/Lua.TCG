local Deck = {}

Deck.SUITS = {
    hearts   = { id = "hearts",   name = "Cơ",    symbol = "♥", color = { 0.92, 0.22, 0.28, 1 } },
    diamonds = { id = "diamonds", name = "Rô",    symbol = "♦", color = { 0.95, 0.45, 0.15, 1 } },
    clubs    = { id = "clubs",    name = "Chuồn", symbol = "♣", color = { 0.18, 0.72, 0.48, 1 } },
    spades   = { id = "spades",   name = "Bích",  symbol = "♠", color = { 0.32, 0.46, 0.85, 1 } },
}

Deck.SUIT_ORDER = { "hearts", "diamonds", "clubs", "spades" }

Deck.RANK_NAMES = {
    [1] = "A",
    [2] = "2", [3] = "3", [4] = "4", [5] = "5", [6] = "6",
    [7] = "7", [8] = "8", [9] = "9", [10] = "10",
    [11] = "J", [12] = "Q", [13] = "K", [14] = "A"
}

function Deck.getChipValue(rank)
    if rank == 1 then
        return 1
    elseif rank == 14 then
        return 11
    elseif rank >= 10 and rank <= 13 then
        return 10
    else
        return rank
    end
end

local nextCardId = 1
function Deck.newCard(rank, suit)
    local suitInfo = Deck.SUITS[suit] or Deck.SUITS.hearts
    local card = {
        id = nextCardId,
        rank = rank,
        baseRank = rank, -- Persistent rank restored across encounters
        suit = suit,
        suitName = suitInfo.name,
        suitSymbol = suitInfo.symbol,
        rankName = Deck.RANK_NAMES[rank] or tostring(rank),
        color = suitInfo.color,
        baseChips = Deck.getChipValue(rank),
        equipments = {}, -- Up to 5 equipment slots
        -- Visual properties
        x = 0,
        y = 0,
        selected = false,
        hovered = false,
        scale = 1.0,
        rotation = 0,
        alpha = 1.0,
    }
    nextCardId = nextCardId + 1
    return card
end

-- Create starter deck of exactly 3 RANDOM cards of the chosen suit
function Deck.createStarterDeck(suit)
    local cards = {}
    local pool = { 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13 }
    for i = #pool, 2, -1 do
        local j = love.math and love.math.random(i) or math.random(i)
        pool[i], pool[j] = pool[j], pool[i]
    end
    for i = 1, 3 do
        table.insert(cards, Deck.newCard(pool[i], suit))
    end
    return cards
end

-- Degrade card rank by 1 on play. A (rank 1) being degraded causes the card to break ("destroyed")
function Deck.degradeCard(card)
    if card.rank > 2 then
        card.rank = card.rank - 1
        card.rankName = Deck.RANK_NAMES[card.rank] or tostring(card.rank)
        card.baseChips = Deck.getChipValue(card.rank)
        return "degraded"
    elseif card.rank == 2 then
        card.rank = 1
        card.rankName = "A"
        card.baseChips = Deck.getChipValue(1)
        return "degraded"
    elseif card.rank == 1 then
        return "destroyed"
    end
    return "degraded"
end

-- Upgrade card rank by 1 (used in Rest Site / Forge to restore durability)
function Deck.upgradeCard(card)
    local bRank = card.baseRank or card.rank
    if bRank == 1 then
        bRank = 2
    elseif bRank < 13 then
        bRank = bRank + 1
    end
    card.baseRank = bRank
    card.rank = bRank
    card.rankName = Deck.RANK_NAMES[card.rank] or tostring(card.rank)
    card.baseChips = Deck.getChipValue(card.rank)
    return card
end

-- Restore all cards in a deck back to their persistent baseRank
function Deck.restoreDeck(deck)
    for _, card in ipairs(deck) do
        local bRank = card.baseRank or card.rank
        card.rank = bRank
        card.rankName = Deck.RANK_NAMES[card.rank] or tostring(card.rank)
        card.baseChips = Deck.getChipValue(card.rank)
        card.selected = false
        card.hovered = false
    end
    return deck
end

-- Clone card cleanly with separate table reference for combat
function Deck.cloneCard(card)
    local newC = Deck.newCard(card.baseRank or card.rank, card.suit)
    newC.id = card.id -- Preserve exact persistent card identity
    newC.baseRank = card.baseRank or card.rank
    newC.rank = newC.baseRank
    newC.rankName = Deck.RANK_NAMES[newC.rank] or tostring(newC.rank)
    newC.baseChips = Deck.getChipValue(newC.rank)
    newC.selected = false
    newC.hovered = false
    newC.equipments = {}
    if card.equipments then
        for _, eq in ipairs(card.equipments) do
            local eqCopy = {}
            for k, v in pairs(eq) do eqCopy[k] = v end
            table.insert(newC.equipments, eqCopy)
        end
    end
    return newC
end

-- Safely add a card to player's persistent deck without duplicating
function Deck.addCardToDeck(gameState, card)
    if not card then return nil end
    card.baseRank = card.baseRank or card.rank
    card.rank = card.baseRank
    card.rankName = Deck.RANK_NAMES[card.rank] or tostring(card.rank)
    card.baseChips = Deck.getChipValue(card.rank)
    card.selected = false
    card.hovered = false
    card.equipments = card.equipments or {}

    if not gameState.persistentDeck then
        gameState.persistentDeck = {}
    end
    -- Prevent duplicate references or duplicate IDs
    for _, c in ipairs(gameState.persistentDeck) do
        if c == card or c.id == card.id then
            return c
        end
    end
    table.insert(gameState.persistentDeck, card)
    gameState.masterDeck = gameState.persistentDeck
    return card
end

-- Get remaining durability uses
function Deck.getDurabilityUses(card)
    if card.rank == 1 then
        return 1
    else
        return card.rank
    end
end

-- Create pure mono-suit deck of 52 cards (4 copies of each rank 2..14)
function Deck.createMonoSuitDeck(suit)
    local cards = {}
    for copy = 1, 4 do
        for rank = 2, 14 do
            table.insert(cards, Deck.newCard(rank, suit))
        end
    end
    return cards
end

-- Create cross-suit reward card for boss chest
function Deck.createRewardCard(excludeSuit)
    local availableSuits = {}
    for _, s in ipairs(Deck.SUIT_ORDER) do
        if s ~= excludeSuit then
            table.insert(availableSuits, s)
        end
    end
    local suit = availableSuits[love.math and love.math.random(#availableSuits) or 1]
    -- Random high rank: 10, J, Q, K, A
    local ranks = { 10, 11, 12, 13, 14 }
    local rank = ranks[love.math and love.math.random(#ranks) or 5]

    local card = Deck.newCard(rank, suit)
    return card
end

function Deck.shuffle(deck)
    local n = #deck
    for i = n, 2, -1 do
        local j = love.math and love.math.random(i) or math.random(i)
        deck[i], deck[j] = deck[j], deck[i]
    end
    return deck
end

function Deck.sortByRank(hand)
    table.sort(hand, function(a, b)
        if a.rank == b.rank then
            return a.suit < b.suit
        end
        return a.rank > b.rank
    end)
end

function Deck.sortBySuit(hand)
    local suitOrderMap = { hearts = 1, diamonds = 2, clubs = 3, spades = 4 }
    table.sort(hand, function(a, b)
        local sa = suitOrderMap[a.suit] or 99
        local sb = suitOrderMap[b.suit] or 99
        if sa == sb then
            return a.rank > b.rank
        end
        return sa < sb
    end)
end

return Deck
