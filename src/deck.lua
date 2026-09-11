local Deck = {}

Deck.FACTIONS = {
    aurelia = {
        id = "aurelia",
        name = "Aurelia",
        fullName = "Aurelia — Phe Ánh Sáng",
        vnName = "Ánh Sáng",
        symbol = "☀️",
        color = { 1.0, 0.82, 0.22, 1 },
        icon = "☀️",
        passive1 = "Hào Quang Thánh Thiện: Đòn đánh chứa thẻ Aurelia nhận x1.15 XMult.",
        passive2 = "Kỷ Luật Thần Thánh: Bài hình (J, Q, K) cố định điểm, miễn nhiễm debuff quái vật.",
    },
    elaris = {
        id = "elaris",
        name = "Elaris",
        fullName = "Elaris — Phe Thiên Nhiên",
        vnName = "Thiên Nhiên",
        symbol = "🌲",
        color = { 0.22, 0.82, 0.42, 1 },
        icon = "🌲",
        passive1 = "Sức Sống Rừng Già: Giới hạn giữ bài trên tay +1 (9 lá) & tái chế Chiến Binh khi đổi bài.",
        passive2 = "Lộc Biếc Đâm Chồi: Thắng trận không mất quá nửa lượt đánh giúp nâng cấp/phục hồi 1 lá bài.",
    },
    vharos = {
        id = "vharos",
        name = "Vharos",
        fullName = "Vharos — Phe Hắc Ám",
        vnName = "Hắc Ám",
        symbol = "🔥",
        color = { 0.92, 0.25, 0.35, 1 },
        icon = "🔥",
        passive1 = "Hơi Thở Ma Quỷ: Thẻ Vharos khi xuất trận cộng trực tiếp +40 Chips.",
        passive2 = "Huyết Tế Bóng Đêm: Khi Chiến Binh (2-10) bị hy sinh/tiêu hủy, gây sát thương chuẩn bằng số của lá đó.",
    },
    valoria = {
        id = "valoria",
        name = "Valoria",
        fullName = "Valoria — Phe Nhân Loại",
        vnName = "Nhân Loại",
        symbol = "⚔️",
        color = { 0.35, 0.65, 0.95, 1 },
        icon = "⚔️",
        passive1 = "Chiến Thuật Hành Quân: Nhận thêm +1 Lượt Đổi Bài (Discard) miễn phí mỗi trận.",
        passive2 = "Hậu Cần Quân Khí: Tiêu diệt quái vật bằng đội hình Valoria tăng +25% vàng thu thập.",
    },
}

-- Backward compatibility aliases
Deck.SUITS = Deck.FACTIONS
Deck.SUITS.hearts   = Deck.FACTIONS.aurelia
Deck.SUITS.diamonds = Deck.FACTIONS.valoria
Deck.SUITS.clubs    = Deck.FACTIONS.elaris
Deck.SUITS.spades   = Deck.FACTIONS.vharos

Deck.FACTION_ORDER = { "aurelia", "elaris", "vharos", "valoria" }
Deck.SUIT_ORDER = Deck.FACTION_ORDER

Deck.RANK_NAMES = {
    [1] = "A",
    [2] = "2", [3] = "3", [4] = "4", [5] = "5", [6] = "6",
    [7] = "7", [8] = "8", [9] = "9", [10] = "10",
    [11] = "J", [12] = "Q", [13] = "K", [14] = "A"
}

Deck.CARD_ROLES = {
    soldier = {
        id = "soldier",
        name = "Chiến Binh",
        title = "Hàng Ngũ Chiến Binh (2-10)",
        icon = "🛡️",
        desc = "Lực lượng nòng cốt xếp các thế bài cơ bản. Điểm số tăng dần từ 2 đến 10.",
    },
    knight = {
        id = "knight",
        name = "Hiệp Sĩ",
        title = "Hiệp Sĩ / Cận Vệ (J)",
        icon = "🗡️",
        desc = "Bản lề chiến thuật: Tăng thêm +15 Chips & +2 Mult cho mỗi lá Chiến Binh đứng cùng.",
    },
    queen = {
        id = "queen",
        name = "Hoàng Hậu",
        title = "Hoàng Hậu / Phù Sư (Q)",
        icon = "👑",
        desc = "Tương tác trang bị: Tự đem lại x1.1 XMult, +15 Chips & +2 Mult cho mỗi ô trang bị đã khảm.",
    },
    king = {
        id = "king",
        name = "Quốc Vương",
        title = "Quốc Vương / Lãnh Chúa (K)",
        icon = "🏰",
        desc = "Sức mạnh áp đảo: Trụ cột dồn sát thương nặng ký, cộng trực tiếp +25 Chips & +5 Mult.",
    },
    ace = {
        id = "ace",
        name = "Thần Khí",
        title = "Át Chủ Bài / Thần Khí (A)",
        icon = "⚡",
        desc = "Linh hoạt tối đa: Có thể làm đầu/cuối trong Sảnh và kích hoạt cộng hưởng phe phái.",
    },
}

function Deck.getCardRole(rank)
    if rank >= 2 and rank <= 10 then
        return Deck.CARD_ROLES.soldier
    elseif rank == 11 then
        return Deck.CARD_ROLES.knight
    elseif rank == 12 then
        return Deck.CARD_ROLES.queen
    elseif rank == 13 then
        return Deck.CARD_ROLES.king
    elseif rank == 1 or rank == 14 then
        return Deck.CARD_ROLES.ace
    end
    return Deck.CARD_ROLES.soldier
end

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
    local suitInfo = Deck.FACTIONS[suit] or Deck.SUITS[suit] or Deck.FACTIONS.aurelia
    local actualSuit = suitInfo.id
    local role = Deck.getCardRole(rank)

    local card = {
        id = nextCardId,
        rank = rank,
        baseRank = rank, -- Persistent rank
        suit = actualSuit,
        suitName = suitInfo.name,
        suitSymbol = suitInfo.symbol,
        rankName = Deck.RANK_NAMES[rank] or tostring(rank),
        color = suitInfo.color,
        baseChips = Deck.getChipValue(rank),
        role = role.id,
        roleName = role.name,
        roleTitle = role.title,
        roleIcon = role.icon,
        roleDesc = role.desc,
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

-- Create starter deck of exactly 3 RANDOM cards of the chosen faction
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
    newC.role = card.role or newC.role
    newC.roleName = card.roleName or newC.roleName
    newC.roleTitle = card.roleTitle or newC.roleTitle
    newC.roleIcon = card.roleIcon or newC.roleIcon
    newC.roleDesc = card.roleDesc or newC.roleDesc
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
    local role = Deck.getCardRole(card.rank)
    card.role = role.id
    card.roleName = role.name
    card.roleTitle = role.title
    card.roleIcon = role.icon
    card.roleDesc = role.desc
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
    local suitOrderMap = { aurelia = 1, elaris = 2, vharos = 3, valoria = 4, hearts = 1, diamonds = 2, clubs = 3, spades = 4 }
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
