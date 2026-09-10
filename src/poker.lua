local Poker = {}

Poker.HAND_TYPES = {
    STRAIGHT_FLUSH = { id = "straight_flush", name = "Straight Flush", vnName = "VẠN KIẾM QUY TÔNG", subtitle = "Thùng phá sảnh", baseChips = 100, baseMult = 8, order = 9, requiredCards = 5 },
    FOUR_OF_A_KIND = { id = "four_of_a_kind", name = "Four of a Kind", vnName = "TỨ TƯỢNG", subtitle = "Tứ quý", baseChips = 60, baseMult = 7, order = 8, requiredCards = 4 },
    FULL_HOUSE     = { id = "full_house",     name = "Full House",     vnName = "HỖN NGUYÊN", subtitle = "Cù lũ", baseChips = 40, baseMult = 4, order = 7, requiredCards = 5 },
    FLUSH          = { id = "flush",          name = "Flush",          vnName = "ĐỒNG KHÍ", subtitle = "Thùng", baseChips = 35, baseMult = 4, order = 6, requiredCards = 5 },
    STRAIGHT       = { id = "straight",       name = "Straight",       vnName = "TRƯỜNG LONG", subtitle = "Sảnh", baseChips = 30, baseMult = 4, order = 5, requiredCards = 5 },
    THREE_OF_A_KIND= { id = "three_of_a_kind",name = "Three of a Kind",vnName = "TAM HOA", subtitle = "Sám cô", baseChips = 30, baseMult = 3, order = 4, requiredCards = 3 },
    TWO_PAIR       = { id = "two_pair",       name = "Two Pair",       vnName = "SONG ĐÔI", subtitle = "Hai đôi", baseChips = 20, baseMult = 2, order = 3, requiredCards = 4 },
    PAIR           = { id = "pair",           name = "Pair",           vnName = "SONG ĐAO", subtitle = "Đôi", baseChips = 10, baseMult = 2, order = 2, requiredCards = 2 },
    HIGH_CARD      = { id = "high_card",      name = "High Card",      vnName = "ĐƠN THỦ", subtitle = "Mậu thầu (1 lá)", baseChips = 5, baseMult = 1, order = 1, requiredCards = 1 },
}

Poker.HAND_TYPES_ORDERED = {
    Poker.HAND_TYPES.STRAIGHT_FLUSH,
    Poker.HAND_TYPES.FOUR_OF_A_KIND,
    Poker.HAND_TYPES.FULL_HOUSE,
    Poker.HAND_TYPES.FLUSH,
    Poker.HAND_TYPES.STRAIGHT,
    Poker.HAND_TYPES.THREE_OF_A_KIND,
    Poker.HAND_TYPES.TWO_PAIR,
    Poker.HAND_TYPES.PAIR,
    Poker.HAND_TYPES.HIGH_CARD,
}

Poker.SKILL_BOOKS = {
    pair = {
        id = "book_pair",
        handId = "pair",
        name = "Bí Tịch: Song Đao",
        handName = "SONG ĐAO (Đôi)",
        cost = 5,
        desc = "Mở khóa vĩnh viễn tay bài SONG ĐAO (Đôi). Đánh ra 2 lá cùng số (10 Chips × 2 Mult).",
        color = { 0.3, 0.7, 0.9, 1 },
    },
    two_pair = {
        id = "book_two_pair",
        handId = "two_pair",
        name = "Bí Tịch: Song Đôi",
        handName = "SONG ĐÔI (Hai Đôi)",
        cost = 6,
        desc = "Mở khóa vĩnh viễn tay bài SONG ĐÔI (Hai Đôi). Đánh ra 2 cặp lá cùng số (20 Chips × 2 Mult).",
        color = { 0.35, 0.75, 0.85, 1 },
    },
    three_of_a_kind = {
        id = "book_three_of_a_kind",
        handId = "three_of_a_kind",
        name = "Bí Tịch: Tam Hoa",
        handName = "TAM HOA (Sám Cô)",
        cost = 7,
        desc = "Mở khóa vĩnh viễn tay bài TAM HOA (Sám Cô). Đánh ra 3 lá cùng số (30 Chips × 3 Mult).",
        color = { 0.5, 0.85, 0.4, 1 },
    },
    straight = {
        id = "book_straight",
        handId = "straight",
        name = "Bí Tịch: Trường Long",
        handName = "TRƯỜNG LONG (Sảnh)",
        cost = 8,
        desc = "Mở khóa vĩnh viễn tay bài TRƯỜNG LONG (Sảnh). 5 lá số liên tiếp nhau (30 Chips × 4 Mult).",
        color = { 0.95, 0.7, 0.2, 1 },
    },
    flush = {
        id = "book_flush",
        handId = "flush",
        name = "Bí Tịch: Đồng Khí",
        handName = "ĐỒNG KHÍ (Thùng)",
        cost = 9,
        desc = "Mở khóa vĩnh viễn tay bài ĐỒNG KHÍ (Thùng). 5 lá cùng chất màu (35 Chips × 4 Mult).",
        color = { 0.95, 0.4, 0.5, 1 },
    },
    full_house = {
        id = "book_full_house",
        handId = "full_house",
        name = "Bí Tịch: Hỗn Nguyên",
        handName = "HỖN NGUYÊN (Cù Lũ)",
        cost = 10,
        desc = "Mở khóa vĩnh viễn tay bài HỖN NGUYÊN (Cù Lũ). Gồm 1 bộ ba và 1 bộ đôi (40 Chips × 4 Mult).",
        color = { 0.8, 0.4, 0.9, 1 },
    },
    four_of_a_kind = {
        id = "book_four_of_a_kind",
        handId = "four_of_a_kind",
        name = "Bí Tịch: Tứ Tượng",
        handName = "TỨ TƯỢNG (Tứ Quý)",
        cost = 12,
        desc = "Mở khóa vĩnh viễn tay bài TỨ TƯỢNG (Tứ Quý). 4 lá cùng số uy lực hủy diệt (60 Chips × 7 Mult).",
        color = { 0.95, 0.25, 0.25, 1 },
    },
    straight_flush = {
        id = "book_straight_flush",
        handId = "straight_flush",
        name = "Bí Tịch: Vạn Kiếm",
        handName = "VẠN KIẾM QUY TÔNG (Thùng Phá Sảnh)",
        cost = 15,
        desc = "Mở khóa tuyệt kỹ tối thượng VẠN KIẾM QUY TÔNG. 5 lá vừa sảnh vừa thùng (100 Chips × 8 Mult).",
        color = { 0.98, 0.85, 0.15, 1 },
    },
}

-- Check if 5 sorted ranks form a straight
local function checkStraight(sortedCards)
    if #sortedCards ~= 5 then return false end
    
    -- Check regular straight (e.g. 14, 13, 12, 11, 10 or 9, 8, 7, 6, 5)
    local isRegular = true
    for i = 1, 4 do
        if sortedCards[i].rank - sortedCards[i + 1].rank ~= 1 then
            isRegular = false
            break
        end
    end
    if isRegular then return true end

    -- Check Ace-low straight: A, 5, 4, 3, 2 (ranks: 14, 5, 4, 3, 2 or 5, 4, 3, 2, 1)
    if (sortedCards[1].rank == 14 and
        sortedCards[2].rank == 5 and
        sortedCards[3].rank == 4 and
        sortedCards[4].rank == 3 and
        sortedCards[5].rank == 2) or
       (sortedCards[1].rank == 5 and
        sortedCards[2].rank == 4 and
        sortedCards[3].rank == 3 and
        sortedCards[4].rank == 2 and
        sortedCards[5].rank == 1) then
        return true
    end

    return false
end

-- Check if 5 cards have the same suit
local function checkFlush(cards)
    if #cards ~= 5 then return false end
    local suit = cards[1].suit
    for i = 2, #cards do
        if cards[i].suit ~= suit then
            return false
        end
    end
    return true
end

local function getUnscoredCards(allCards, scoringCards)
    local unscored = {}
    for _, c in ipairs(allCards) do
        local isScored = false
        for _, sc in ipairs(scoringCards) do
            if sc == c then
                isScored = true
                break
            end
        end
        if not isScored then
            table.insert(unscored, c)
        end
    end
    return unscored
end

-- Find all valid poker hands that the given cards can make, ordered by rank
local function getPossibleHands(sorted)
    local hands = {}

    local countByRank = {}
    local rankGroups = {}
    for _, c in ipairs(sorted) do
        countByRank[c.rank] = (countByRank[c.rank] or 0) + 1
        rankGroups[c.rank] = rankGroups[c.rank] or {}
        table.insert(rankGroups[c.rank], c)
    end

    local fourRank, threeRank
    local pairRanks = {}
    for rank, count in pairs(countByRank) do
        if count == 4 then
            fourRank = rank
        elseif count == 3 then
            threeRank = rank
        elseif count == 2 then
            table.insert(pairRanks, rank)
        end
    end
    table.sort(pairRanks, function(a, b) return a > b end)

    local isFlush = checkFlush(sorted)
    local isStraight = checkStraight(sorted)

    -- 1. Straight Flush (Order 9)
    if isFlush and isStraight then
        table.insert(hands, {
            type = Poker.HAND_TYPES.STRAIGHT_FLUSH,
            scoringCards = sorted,
            unscoredCards = {},
        })
    end

    -- 2. Four of a Kind (Order 8)
    if fourRank then
        local scoring = rankGroups[fourRank]
        table.insert(hands, {
            type = Poker.HAND_TYPES.FOUR_OF_A_KIND,
            scoringCards = scoring,
            unscoredCards = getUnscoredCards(sorted, scoring),
        })
    end

    -- 3. Full House (Order 7)
    if threeRank and #pairRanks >= 1 then
        local scoring = {}
        for _, c in ipairs(rankGroups[threeRank]) do table.insert(scoring, c) end
        for _, c in ipairs(rankGroups[pairRanks[1]]) do table.insert(scoring, c) end
        table.insert(hands, {
            type = Poker.HAND_TYPES.FULL_HOUSE,
            scoringCards = scoring,
            unscoredCards = getUnscoredCards(sorted, scoring),
        })
    end

    -- 4. Flush (Order 6)
    if isFlush then
        table.insert(hands, {
            type = Poker.HAND_TYPES.FLUSH,
            scoringCards = sorted,
            unscoredCards = {},
        })
    end

    -- 5. Straight (Order 5)
    if isStraight then
        table.insert(hands, {
            type = Poker.HAND_TYPES.STRAIGHT,
            scoringCards = sorted,
            unscoredCards = {},
        })
    end

    -- 6. Three of a Kind (Order 4)
    if threeRank or fourRank then
        local tRank = threeRank or fourRank
        local scoring = { rankGroups[tRank][1], rankGroups[tRank][2], rankGroups[tRank][3] }
        table.insert(hands, {
            type = Poker.HAND_TYPES.THREE_OF_A_KIND,
            scoringCards = scoring,
            unscoredCards = getUnscoredCards(sorted, scoring),
        })
    end

    -- 7. Two Pair (Order 3)
    if #pairRanks >= 2 or fourRank or (threeRank and #pairRanks >= 1) then
        local scoring = {}
        if fourRank then
            scoring = { rankGroups[fourRank][1], rankGroups[fourRank][2], rankGroups[fourRank][3], rankGroups[fourRank][4] }
        elseif #pairRanks >= 2 then
            for _, c in ipairs(rankGroups[pairRanks[1]]) do table.insert(scoring, c) end
            for _, c in ipairs(rankGroups[pairRanks[2]]) do table.insert(scoring, c) end
        elseif threeRank and #pairRanks >= 1 then
            table.insert(scoring, rankGroups[threeRank][1])
            table.insert(scoring, rankGroups[threeRank][2])
            table.insert(scoring, rankGroups[pairRanks[1]][1])
            table.insert(scoring, rankGroups[pairRanks[1]][2])
        end
        if #scoring == 4 then
            table.insert(hands, {
                type = Poker.HAND_TYPES.TWO_PAIR,
                scoringCards = scoring,
                unscoredCards = getUnscoredCards(sorted, scoring),
            })
        end
    end

    -- 8. Pair (Order 2)
    if #pairRanks >= 1 or threeRank or fourRank then
        local pRank = pairRanks[1] or threeRank or fourRank
        local scoring = { rankGroups[pRank][1], rankGroups[pRank][2] }
        table.insert(hands, {
            type = Poker.HAND_TYPES.PAIR,
            scoringCards = scoring,
            unscoredCards = getUnscoredCards(sorted, scoring),
        })
    end

    -- 9. High Card (Order 1)
    local highScoring = { sorted[1] }
    table.insert(hands, {
        type = Poker.HAND_TYPES.HIGH_CARD,
        scoringCards = highScoring,
        unscoredCards = getUnscoredCards(sorted, highScoring),
    })

    return hands
end

function Poker.evaluate(cards, unlockedHands)
    if not cards or #cards == 0 then return nil end

    -- Shallow copy sorted descending by rank
    local sorted = {}
    for _, c in ipairs(cards) do table.insert(sorted, c) end
    table.sort(sorted, function(a, b)
        if a.rank == b.rank then return a.suit < b.suit end
        return a.rank > b.rank
    end)

    local possibleHands = getPossibleHands(sorted)
    if #possibleHands == 0 then return nil end

    local naturalHand = possibleHands[1]

    -- If unlockedHands not specified, allow all (standard poker evaluation)
    if not unlockedHands then
        return naturalHand
    end

    -- Return the highest-ranking valid hand that has been unlocked
    for _, hand in ipairs(possibleHands) do
        if unlockedHands[hand.type.id] then
            if hand.type.order < naturalHand.type.order then
                hand.lockedHandAttempted = naturalHand.type.vnName
            end
            return hand
        end
    end

    -- Default fallback: High Card (always unlocked)
    local fallback = possibleHands[#possibleHands]
    if naturalHand.type.order > fallback.type.order then
        fallback.lockedHandAttempted = naturalHand.type.vnName
    end
    return fallback
end

return Poker
