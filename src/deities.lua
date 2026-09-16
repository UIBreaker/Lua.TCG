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
            if card.suit == "hearts" or card.suit == "valoria" then
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
            if card.suit == "diamonds" or card.suit == "aurelia" then
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
                if c.suit == "spades" or c.suit == "vharos" then
                    return { xMult = 1.5, message = "Bích x1.5 Mult!" }
                end
            end
        end,
    },

    -- 10 Core Balatro-Adapted Deities
    -- 1. Joker cơ bản -> Thần Khởi Nguyên (+4 Mult vô điều kiện)
    deity_genesis = {
        id = "deity_genesis",
        name = "Thần Khởi Nguyên",
        rarity = "common",
        cost = 4,
        desc = "+4 Mult vô điều kiện cho mọi tay bài đánh ra",
        onHandScored = function(handInfo, ctx, self)
            return { addMult = 4, message = "Khởi Nguyên +4 Mult!" }
        end,
    },

    -- 2. Greedy/Lusty/Wrathful/Gluttonous Joker -> Tứ Đại Thần Tộc (+4 Mult mỗi lá thuộc Phe)
    deity_aurelia = {
        id = "deity_aurelia",
        name = "Thần Quang Huy",
        rarity = "common",
        cost = 5,
        desc = "+4 Mult cho mỗi lá phe Aurelia (Ánh Sáng) ghi điểm",
        onCardScored = function(card, ctx, self)
            if card.suit == "aurelia" or card.suit == "diamonds" then
                return { addMult = 4, message = "Quang Huy +4 Mult!" }
            end
        end,
    },
    deity_elaris = {
        id = "deity_elaris",
        name = "Thần Trường Sinh",
        rarity = "common",
        cost = 5,
        desc = "+4 Mult cho mỗi lá phe Elaris (Thiên Nhiên) ghi điểm",
        onCardScored = function(card, ctx, self)
            if card.suit == "elaris" or card.suit == "clubs" then
                return { addMult = 4, message = "Trường Sinh +4 Mult!" }
            end
        end,
    },
    deity_vharos = {
        id = "deity_vharos",
        name = "Thần Huyết Lửa",
        rarity = "common",
        cost = 5,
        desc = "+4 Mult cho mỗi lá phe Vharos (Hắc Ám) ghi điểm",
        onCardScored = function(card, ctx, self)
            if card.suit == "vharos" or card.suit == "spades" then
                return { addMult = 4, message = "Huyết Lửa +4 Mult!" }
            end
        end,
    },
    deity_valoria = {
        id = "deity_valoria",
        name = "Thần Thiết Huyết",
        rarity = "common",
        cost = 5,
        desc = "+4 Mult cho mỗi lá phe Valoria (Nhân Loại) ghi điểm",
        onCardScored = function(card, ctx, self)
            if card.suit == "valoria" or card.suit == "hearts" then
                return { addMult = 4, message = "Thiết Huyết +4 Mult!" }
            end
        end,
    },

    -- 3. Sly/Wily/Clever Joker -> Thần Trận Pháp (+50 Chips cho Song Đao / Tam Hoa)
    deity_formation = {
        id = "deity_formation",
        name = "Thần Trận Pháp",
        rarity = "common",
        cost = 5,
        desc = "+50 Chips nếu tay bài là Song Đao hoặc Tam Hoa",
        onHandScored = function(handInfo, ctx, self)
            local hId = handInfo.type and handInfo.type.id
            if hId == "pair" or hId == "two_pair" or hId == "three_of_a_kind" or hId == "full_house" then
                return { addChips = 50, message = "Trận Pháp +50 Chips!" }
            end
        end,
    },

    -- 4. Half Joker -> Thần Tinh Binh (+20 Mult nếu tay bài <= 3 lá bài)
    deity_elite = {
        id = "deity_elite",
        name = "Thần Tinh Binh",
        rarity = "common",
        cost = 5,
        desc = "+20 Mult nếu tay bài đánh ra có <= 3 lá bài",
        onHandScored = function(handInfo, ctx, self)
            local totalCards = #(handInfo.scoringCards or {}) + #(handInfo.unscoredCards or {})
            if totalCards <= 3 then
                return { addMult = 20, message = "Tinh Binh +20 Mult!" }
            end
        end,
    },

    -- 5. Banner -> Thần Chiến Kỷ (+30 Chips cho mỗi lượt Discard còn lại)
    deity_banner = {
        id = "deity_banner",
        name = "Thần Chiến Kỷ",
        rarity = "common",
        cost = 5,
        desc = "+30 Chips cho mỗi lượt Đổi Bài (Discard) còn lại",
        onHandScored = function(handInfo, ctx, self)
            local discards = (ctx and ctx.discardsRemaining) or 0
            if discards > 0 then
                local bonus = discards * 30
                return { addChips = bonus, message = "Chiến Kỷ +" .. bonus .. " Chips (" .. discards .. " Đổi)!" }
            end
        end,
    },

    -- 6. Popcorn -> Thần Bách Hoa (+20 Mult ban đầu, -4 Mult sau mỗi trận cho đến khi tan biến)
    deity_floral = {
        id = "deity_floral",
        name = "Thần Bách Hoa",
        rarity = "common",
        cost = 5,
        currentMult = 20,
        desc = "+20 Mult ban đầu (giảm -4 Mult sau mỗi trận thắng)",
        onHandScored = function(handInfo, ctx, self)
            local cur = (self and self.currentMult) or 20
            if cur > 0 then
                return { addMult = cur, message = "Bách Hoa +" .. cur .. " Mult!" }
            end
        end,
        onRoundWin = function(game, self)
            local cur = (self and self.currentMult) or 20
            cur = cur - 4
            if self then
                self.currentMult = cur
                self.desc = "+" .. math.max(0, cur) .. " Mult ban đầu (giảm -4 Mult sau mỗi trận)"
                if cur <= 0 then
                    self.extinct = true
                    return { message = "Thần Bách Hoa đã cạn kiệt linh lực và tan biến!" }
                end
            end
            return { message = "Thần Bách Hoa tàn phai còn +" .. cur .. " Mult" }
        end,
    },

    -- 7. Golden Joker -> Thần Kim Tài (+$4 Vàng khi thắng trận)
    deity_golden = {
        id = "deity_golden",
        name = "Thần Kim Tài",
        rarity = "common",
        cost = 6,
        desc = "Nhận +$4 Vàng khi chiến thắng mỗi trận",
        onRoundWin = function(game, self)
            return { addGold = 4, message = "+$4 Vàng từ Thần Kim Tài!" }
        end,
    },

    -- 8. Gros Michel -> Thần Quả Thần Bí (+15 Mult, 1/6 tự hủy mở khóa Thần Thụ Bất Diệt)
    deity_sacred_fruit = {
        id = "deity_sacred_fruit",
        name = "Thần Quả Thần Bí",
        rarity = "common",
        cost = 5,
        desc = "+15 Mult. Có 1/6 tỉ lệ thăng thiên sau mỗi trận (mở khóa Thần Bất Diệt)",
        onHandScored = function(handInfo, ctx, self)
            return { addMult = 15, message = "Quả Thần Bí +15 Mult!" }
        end,
        onRoundWin = function(game, self)
            local roll = (love and love.math and love.math.random(6)) or math.random(6)
            if roll == 1 then
                if self then self.extinct = true end
                if game then game.sacredFruitExtinct = true end
                return { message = "Thần Quả Thần Bí đã thăng thiên! (Mở khóa Thần Bất Diệt trong Shop)" }
            end
        end,
    },
    -- Cavendish -> Thần Thụ Bất Diệt (x3.0 XMult vĩnh viễn)
    deity_eternal_tree = {
        id = "deity_eternal_tree",
        name = "Thần Thụ Bất Diệt",
        rarity = "rare",
        cost = 8,
        requiresExtinct = "deity_sacred_fruit",
        desc = "x3.0 XMult vĩnh viễn cho mọi tay bài",
        onHandScored = function(handInfo, ctx, self)
            return { xMult = 3.0, message = "Thần Thụ Bất Diệt ×3.0 Mult!" }
        end,
    },

    -- 9. Card Sharp -> Thần Điệp Kích (x3.0 XMult nếu thế bài được chơi lặp lại trong cùng trận)
    deity_echo = {
        id = "deity_echo",
        name = "Thần Điệp Kích",
        rarity = "rare",
        cost = 7,
        desc = "x3.0 XMult nếu thế bài này đã được chơi trong trận",
        onHandScored = function(handInfo, ctx, self)
            local handId = handInfo.type and handInfo.type.id
            if ctx and ctx.playedHandsHistory and handId and (ctx.playedHandsHistory[handId] or 0) >= 1 then
                return { xMult = 3.0, message = "Điệp Kích ×3.0 Mult (Thế bài lặp lại)!" }
            end
        end,
    },

    -- 10. Blueprint -> Thần Phản Chiếu (Sao chép Thần bên phải)
    deity_mirror = {
        id = "deity_mirror",
        name = "Thần Phản Chiếu",
        rarity = "legendary",
        cost = 10,
        isCopyDeity = true,
        desc = "Sao chép toàn bộ kỹ năng của Thần Bài đứng ngay bên phải nó",
    },

    -- Shop & discoverable deities
    deity_generous = {
        id = "deity_generous",
        name = "Thần Hào Phóng",
        rarity = "common",
        cost = 4,
        desc = "+50 Chips cố định vào mỗi tay bài",
        onHandScored = function(handInfo, ctx, self)
            return { addChips = 50, message = "+50 Chips!" }
        end,
    },
    deity_flame = {
        id = "deity_flame",
        name = "Thần Bùng Nổ",
        rarity = "common",
        cost = 4,
        desc = "+6 Mult cho mọi tay bài",
        onHandScored = function(handInfo, ctx, self)
            return { addMult = 6, message = "+6 Mult!" }
        end,
    },
    deity_pairs = {
        id = "deity_pairs",
        name = "Thần Cặp Đôi",
        rarity = "uncommon",
        cost = 5,
        desc = "+12 Mult nếu tay bài là Đôi hoặc Hai Đôi",
        onHandScored = function(handInfo, ctx, self)
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
        onHandScored = function(handInfo, ctx, self)
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
        onHandScored = function(handInfo, ctx, self)
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
        onCardScored = function(card, ctx, self)
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
        onHandScored = function(handInfo, ctx, self)
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
        onHandScored = function(handInfo, ctx, self)
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
        onHandScored = function(handInfo, ctx, self)
            if ctx and ctx.handsRemaining == 0 then -- This is the last hand played
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
        onHandScored = function(handInfo, ctx, self)
            return { xMult = 2.0, message = "TỐI THƯỢNG x2.0 Mult!" }
        end,
    },
}

function Deities.getCount(deities)
    if not deities then return 0 end
    local count = 0
    for i = 1, 5 do
        if deities[i] ~= nil then
            count = count + 1
        end
    end
    for k, v in pairs(deities) do
        if type(k) == "number" and (k < 1 or k > 5) and v ~= nil then
            count = count + 1
        end
    end
    return count
end

function Deities.resolveDeity(deities, index)
    if not deities or not deities[index] then return nil end
    local current = deities[index]
    if not current.isCopyDeity then return current end

    -- Blueprint logic: copy first valid non-copy deity to the right (checking slots up to 5)
    local maxLimit = 5
    for k in pairs(deities) do
        if type(k) == "number" and k > maxLimit then
            maxLimit = k
        end
    end
    local targetIdx = index + 1
    while targetIdx <= maxLimit do
        local candidate = deities[targetIdx]
        if candidate and not candidate.isCopyDeity then
            return candidate
        end
        targetIdx = targetIdx + 1
    end
    return nil
end

function Deities.getStarterDeity(suit)
    if suit == "hearts" or suit == "valoria" then
        return Deities.CATALOG.deity_valoria or Deities.CATALOG.deity_hearts
    elseif suit == "diamonds" or suit == "aurelia" then
        return Deities.CATALOG.deity_aurelia or Deities.CATALOG.deity_diamonds
    elseif suit == "clubs" or suit == "elaris" then
        return Deities.CATALOG.deity_elaris or Deities.CATALOG.deity_clubs
    elseif suit == "spades" or suit == "vharos" then
        return Deities.CATALOG.deity_vharos or Deities.CATALOG.deity_spades
    end
    return Deities.CATALOG.deity_genesis or Deities.CATALOG.deity_hearts
end

function Deities.getRandomShopPool(ownedDeities, count, gameState)
    local pool = {}
    local ownedIds = {}
    if ownedDeities then
        for i = 1, 5 do
            local d = ownedDeities[i]
            if d and d.id then ownedIds[d.id] = true end
        end
        for _, d in pairs(ownedDeities) do
            if type(d) == "table" and d.id then ownedIds[d.id] = true end
        end
    end

    local candidates = {}
    for id, d in pairs(Deities.CATALOG) do
        if not ownedIds[id] then
            local allowed = true
            -- Conditional unlock: deity_eternal_tree requires sacred fruit extinction
            if d.requiresExtinct then
                if not (gameState and gameState.sacredFruitExtinct) then
                    allowed = false
                end
            end
            if allowed then
                table.insert(candidates, d)
            end
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
    if ownedDeities then
        for i = 1, 5 do
            local d = ownedDeities[i]
            if d and d.id then ownedIds[d.id] = true end
        end
        for _, d in pairs(ownedDeities) do
            if type(d) == "table" and d.id then ownedIds[d.id] = true end
        end
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

function Deities.addDeity(gameState, deity, preferredSlot)
    if not gameState.deities then
        gameState.deities = {}
    end
    local count = Deities.getCount(gameState.deities)
    if count >= 5 then
        return false
    end
    -- Clone deity so instance state (such as currentMult or extinct) is isolated
    local instance = {}
    for k, v in pairs(deity) do
        instance[k] = v
    end

    if preferredSlot and preferredSlot >= 1 and preferredSlot <= 5 and gameState.deities[preferredSlot] == nil then
        gameState.deities[preferredSlot] = instance
        return true
    end

    for i = 1, 5 do
        if gameState.deities[i] == nil then
            gameState.deities[i] = instance
            return true
        end
    end
    return false
end

return Deities
