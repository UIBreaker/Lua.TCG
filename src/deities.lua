local Deities = {}

Deities.CATALOG = {
    -- Starter deities for each suit
    deity_hearts = {
        id = "deity_hearts",
        name = "Thần Lửa Cơ",
        suit = "hearts",
        rarity = "uncommon",
        cost = 5,
        desc = "+4 Mult cho mỗi lá Cơ ghi điểm",
        onCardScored = function(card, ctx)
            if card.suit == "hearts" then
                return { addMult = 4, message = "Cơ +4 Mult!" }
            end
        end,
    },
    deity_diamonds = {
        id = "deity_diamonds",
        name = "Thần Đất Rô",
        suit = "diamonds",
        rarity = "uncommon",
        cost = 5,
        desc = "+25 Chips cho mỗi lá Rô ghi điểm và +$2 thưởng sau mỗi round",
        onCardScored = function(card, ctx)
            if card.suit == "diamonds" then
                return { addChips = 25, message = "Rô +25 Chips!" }
            end
        end,
        onRoundWin = function(ctx)
            return { addGold = 2, message = "+$2 từ Thần Rô!" }
        end,
    },
    deity_clubs = {
        id = "deity_clubs",
        name = "Thần Gió Chuồn",
        suit = "clubs",
        rarity = "uncommon",
        cost = 5,
        desc = "+1 Discard mỗi round & +30 Chips cho mọi tay bài",
        onRoundStart = function(ctx)
            return { addDiscards = 1 }
        end,
        onHandScored = function(handInfo, ctx)
            return { addChips = 30, message = "Gió Chuồn +30 Chips!" }
        end,
    },
    deity_spades = {
        id = "deity_spades",
        name = "Thần Đêm Bích",
        suit = "spades",
        rarity = "rare",
        cost = 6,
        desc = "x1.5 XMult nếu tay bài đánh ra có ít nhất 1 lá Bích",
        onHandScored = function(handInfo, ctx)
            for _, c in ipairs(handInfo.scoringCards) do
                if c.suit == "spades" then
                    return { xMult = 1.5, message = "Bích x1.5 Mult!" }
                end
            end
        end,
    },

    -- Shop & discoverable deities
    deity_generous = {
        id = "deity_generous",
        name = "Thần Hào Phóng",
        rarity = "common",
        cost = 4,
        desc = "+50 Chips cố định vào mỗi tay bài",
        onHandScored = function(handInfo, ctx)
            return { addChips = 50, message = "+50 Chips!" }
        end,
    },
    deity_flame = {
        id = "deity_flame",
        name = "Thần Bùng Nổ",
        rarity = "common",
        cost = 4,
        desc = "+6 Mult cho mọi tay bài",
        onHandScored = function(handInfo, ctx)
            return { addMult = 6, message = "+6 Mult!" }
        end,
    },
    deity_pairs = {
        id = "deity_pairs",
        name = "Thần Cặp Đôi",
        rarity = "uncommon",
        cost = 5,
        desc = "+12 Mult nếu tay bài là Đôi hoặc Hai Đôi",
        onHandScored = function(handInfo, ctx)
            if handInfo.type.id == "pair" or handInfo.type.id == "two_pair" then
                return { addMult = 12, message = "Đôi +12 Mult!" }
            end
        end,
    },
    deity_straight = {
        id = "deity_straight",
        name = "Đại Thần Sảnh",
        rarity = "uncommon",
        cost = 6,
        desc = "+100 Chips và x1.5 XMult nếu đánh ra Sảnh",
        onHandScored = function(handInfo, ctx)
            if handInfo.type.id == "straight" or handInfo.type.id == "straight_flush" then
                return { addChips = 100, xMult = 1.5, message = "Sảnh x1.5 Mult & +100 Chips!" }
            end
        end,
    },
    deity_flush = {
        id = "deity_flush",
        name = "Thần Đại Dương",
        rarity = "uncommon",
        cost = 6,
        desc = "+15 Mult nếu tay bài là Thùng",
        onHandScored = function(handInfo, ctx)
            if handInfo.type.id == "flush" or handInfo.type.id == "straight_flush" then
                return { addMult = 15, message = "Thùng +15 Mult!" }
            end
        end,
    },
    deity_royalty = {
        id = "deity_royalty",
        name = "Thần Vương Giả",
        rarity = "uncommon",
        cost = 6,
        desc = "+25 Chips cho mỗi lá J, Q, K ghi điểm",
        onCardScored = function(card, ctx)
            if card.rank >= 11 and card.rank <= 13 then
                return { addChips = 25, message = "Tây +25 Chips!" }
            end
        end,
    },
    deity_ace = {
        id = "deity_ace",
        name = "Thần Át Chủ Bài",
        rarity = "rare",
        cost = 7,
        desc = "+15 Mult và x1.5 XMult khi có ít nhất một lá Át ghi điểm",
        onHandScored = function(handInfo, ctx)
            local hasAce = false
            for _, c in ipairs(handInfo.scoringCards) do
                if c.rank == 14 then
                    hasAce = true
                    break
                end
            end
            if hasAce then
                return { addMult = 15, xMult = 1.5, message = "Át x1.5 Mult & +15 Mult!" }
            end
        end,
    },
    deity_fullhouse = {
        id = "deity_fullhouse",
        name = "Thần Cù Lũ",
        rarity = "rare",
        cost = 7,
        desc = "x2.0 XMult nếu đánh ra Cù Lũ hoặc Tứ Quý",
        onHandScored = function(handInfo, ctx)
            if handInfo.type.id == "full_house" or handInfo.type.id == "four_of_a_kind" then
                return { xMult = 2.0, message = "x2.0 Mult Bùng Nổ!" }
            end
        end,
    },
    deity_clutch = {
        id = "deity_clutch",
        name = "Thần Phục Hận",
        rarity = "rare",
        cost = 7,
        desc = "x2.0 XMult ở Lượt đánh (Hand) cuối cùng của round",
        onHandScored = function(handInfo, ctx)
            if ctx.handsRemaining == 0 then -- This is the last hand played
                return { xMult = 2.0, message = "Cú chót x2.0 Mult!" }
            end
        end,
    },
    deity_supreme = {
        id = "deity_supreme",
        name = "Tối Thượng Thần",
        rarity = "legendary",
        cost = 10,
        desc = "x2.0 XMult cho mọi tay bài",
        onHandScored = function(handInfo, ctx)
            return { xMult = 2.0, message = "TỐI THƯỢNG x2.0 Mult!" }
        end,
    },
}

function Deities.getStarterDeity(suit)
    if suit == "hearts" then
        return Deities.CATALOG.deity_hearts
    elseif suit == "diamonds" then
        return Deities.CATALOG.deity_diamonds
    elseif suit == "clubs" then
        return Deities.CATALOG.deity_clubs
    elseif suit == "spades" then
        return Deities.CATALOG.deity_spades
    end
    return Deities.CATALOG.deity_hearts
end

function Deities.getRandomShopPool(ownedDeities, count)
    local pool = {}
    local ownedIds = {}
    for _, d in ipairs(ownedDeities or {}) do
        ownedIds[d.id] = true
    end

    local candidates = {}
    for id, d in pairs(Deities.CATALOG) do
        if not ownedIds[id] then
            table.insert(candidates, d)
        end
    end

    -- Shuffle candidates
    for i = #candidates, 2, -1 do
        local j = math.random(i)
        candidates[i], candidates[j] = candidates[j], candidates[i]
    end

    for i = 1, math.min(count or 3, #candidates) do
        table.insert(pool, candidates[i])
    end

    return pool
end

function Deities.getBossDraftPool(ownedDeities, count)
    count = count or 2
    local pool = {}
    local ownedIds = {}
    for _, d in ipairs(ownedDeities or {}) do
        ownedIds[d.id] = true
    end

    local candidates = {}
    for id, d in pairs(Deities.CATALOG) do
        if not ownedIds[id] then
            table.insert(candidates, d)
        end
    end

    for i = #candidates, 2, -1 do
        local j = math.random(i)
        candidates[i], candidates[j] = candidates[j], candidates[i]
    end

    for i = 1, math.min(count, #candidates) do
        table.insert(pool, candidates[i])
    end

    return pool
end

function Deities.addDeity(gameState, deity)
    if not gameState.deities then
        gameState.deities = {}
    end
    if #gameState.deities < 5 then
        table.insert(gameState.deities, deity)
        return true
    end
    return false
end

return Deities
