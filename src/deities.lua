local Rng = require("src.rng")
local Deities = {}

Deities.CATALOG = {
    -- Starter deities for each suit
    deity_hearts = {
        id = "deity_hearts",
        name = "Tế Đàn Huyết Cơ",
        suit = "hearts",
        rarity = "uncommon",
        cost = 5,
        desc = "+4 Mult cho mỗi lá Cơ ghi điểm",
        lore = "Máu hiến tế nuôi dưỡng ngọn lửa cuồng nộ không bao giờ tắt.",
        onCardScored = function(card, ctx)
            if card.suit == "hearts" or card.suit == "valoria" then
                return { addMult = 4, message = "Cơ +4 Mult!" }
            end
        end,
    },
    deity_diamonds = {
        id = "deity_diamonds",
        name = "Linh Ấn Hoàng Kim",
        suit = "diamonds",
        rarity = "uncommon",
        cost = 5,
        desc = "+25 Chips cho mỗi lá Rô ghi điểm và +$2 thưởng sau mỗi round",
        lore = "Vàng ròng khắc cổ tự mua chuộc cả vận mệnh tử thần.",
        onCardScored = function(card, ctx)
            if card.suit == "diamonds" or card.suit == "aurelia" then
                return { addChips = 25, message = "Rô +25 Chips!" }
            end
        end,
        onRoundWin = function(ctx)
            return { addGold = 2, message = "+$2 từ Linh Ấn!" }
        end,
    },
    deity_clubs = {
        id = "deity_clubs",
        name = "Vuốt Quỷ Nguyên Sinh",
        suit = "clubs",
        rarity = "uncommon",
        cost = 5,
        desc = "+1 Discard mỗi round & +30 Chips cho mọi tay bài",
        lore = "Móng vuốt tàn bạo xé rách ranh giới giữa sự sống và diệt vong.",
        onRoundStart = function(ctx)
            return { addDiscards = 1 }
        end,
        onHandScored = function(handInfo, ctx)
            return { addChips = 30, message = "Vuốt Quỷ +30 Chips!" }
        end,
    },
    deity_spades = {
        id = "deity_spades",
        name = "Thiết Quân Hắc Kiếm",
        suit = "spades",
        rarity = "rare",
        cost = 6,
        desc = "x1.5 XMult nếu tay bài đánh ra có ít nhất 1 lá Bích",
        lore = "Thanh kiếm rèn từ thép thiên thạch đen chém đứt mọi bóng ma.",
        onHandScored = function(handInfo, ctx)
            for _, c in ipairs(handInfo.scoringCards) do
                if c.suit == "spades" or c.suit == "vharos" then
                    return { xMult = 1.5, message = "Bích x1.5 Mult!" }
                end
            end
        end,
    },

    -- 10 Core Balatro-Adapted Deities
    -- 1. Joker cơ bản -> Nguyên Tội Cổ Thần (+4 Mult vô điều kiện)
    deity_genesis = {
        id = "deity_genesis",
        name = "Nguyên Tội Cổ Thần",
        rarity = "common",
        cost = 4,
        desc = "+4 Mult vô điều kiện cho mọi tay bài đánh ra",
        lore = "Tội lỗi khởi nguyên từ thuở hồng hoang vẫn đang gặm nhấm thực tại.",
        onHandScored = function(handInfo, ctx, self)
            return { addMult = 4, message = "Khởi Nguyên +4 Mult!" }
        end,
    },

    -- 2. Greedy/Lusty/Wrathful/Gluttonous Joker -> four suit-based deities.
    deity_aurelia = {
        id = "deity_aurelia",
        name = "Quang Huy Thánh Trọng",
        rarity = "common",
        cost = 5,
        desc = "+4 Mult cho mỗi lá chất Rô ghi điểm",
        lore = "Ánh sáng chói lòa thiêu rụi kẻ dị giáo dưới chân thiên tòa.",
        onCardScored = function(card, ctx, self)
            if card.suit == "aurelia" or card.suit == "diamonds" then
                return { addMult = 4, message = "Quang Huy +4 Mult!" }
            end
        end,
    },
    deity_elaris = {
        id = "deity_elaris",
        name = "Mộc Linh Bất Tử",
        rarity = "common",
        cost = 5,
        desc = "+4 Mult cho mỗi lá chất Chuồn ghi điểm",
        lore = "Rễ cây cổ thụ cắm sâu vào linh hồn người đã khuất.",
        onCardScored = function(card, ctx, self)
            if card.suit == "elaris" or card.suit == "clubs" then
                return { addMult = 4, message = "Trường Sinh +4 Mult!" }
            end
        end,
    },
    deity_vharos = {
        id = "deity_vharos",
        name = "Huyết Ma Tận Diệt",
        rarity = "common",
        cost = 5,
        desc = "+4 Mult cho mỗi lá chất Bích ghi điểm",
        lore = "Bóng tối nuốt chửng tro tàn của những vương triều sụp đổ.",
        onCardScored = function(card, ctx, self)
            if card.suit == "vharos" or card.suit == "spades" then
                return { addMult = 4, message = "Huyết Lửa +4 Mult!" }
            end
        end,
    },
    deity_valoria = {
        id = "deity_valoria",
        name = "Thiết Giáp Bất Bại",
        rarity = "common",
        cost = 5,
        desc = "+4 Mult cho mỗi lá chất Cơ ghi điểm",
        lore = "Ý chí bằng sắt thép không bao giờ cúi đầu trước số phận.",
        onCardScored = function(card, ctx, self)
            if card.suit == "valoria" or card.suit == "hearts" then
                return { addMult = 4, message = "Thiết Huyết +4 Mult!" }
            end
        end,
    },

    -- 3. Sly/Wily/Clever Joker -> Chiến Trận Quân Kỳ (+50 Chips cho Song Đao / Tam Hoa)
    deity_formation = {
        id = "deity_formation",
        name = "Chiến Trận Quân Kỳ",
        rarity = "common",
        cost = 5,
        desc = "+50 Chips nếu tay bài là Song Đao hoặc Tam Hoa",
        lore = "Lá cờ rách nát dựng lên giữa muôn vàn xác lính tử trận.",
        onHandScored = function(handInfo, ctx, self)
            local hId = handInfo.type and handInfo.type.id
            if hId == "pair" or hId == "two_pair" or hId == "three_of_a_kind" or hId == "full_house" then
                return { addChips = 50, message = "Trận Pháp +50 Chips!" }
            end
        end,
    },

    -- 4. Half Joker -> Linh Hồn Tử Sĩ (+20 Mult nếu tay bài <= 3 lá bài)
    deity_elite = {
        id = "deity_elite",
        name = "Linh Hồn Tử Sĩ",
        rarity = "common",
        cost = 5,
        desc = "+20 Mult nếu tay bài đánh ra có <= 3 lá bài",
        lore = "Những chiến binh cảm tử còn sót lại mang theo hận thù ngút trời.",
        onHandScored = function(handInfo, ctx, self)
            local totalCards = #(handInfo.scoringCards or {}) + #(handInfo.unscoredCards or {})
            if totalCards <= 3 then
                return { addMult = 20, message = "Tinh Binh +20 Mult!" }
            end
        end,
    },

    -- 5. Banner -> Huyết Tẩy Tàn Quân (+30 Chips cho mỗi lượt Discard còn lại)
    deity_banner = {
        id = "deity_banner",
        name = "Huyết Tẩy Tàn Quân",
        rarity = "common",
        cost = 5,
        desc = "+30 Chips cho mỗi lượt Đổi Bài (Discard) còn lại",
        lore = "Mỗi nhát cờ phất lên là một linh hồn bị gạt bỏ khỏi nhân gian.",
        onHandScored = function(handInfo, ctx, self)
            local discards = (ctx and ctx.discardsRemaining) or 0
            if discards > 0 then
                local bonus = discards * 30
                return { addChips = bonus, message = "Chiến Kỷ +" .. bonus .. " Chips (" .. discards .. " Đổi)!" }
            end
        end,
    },

    -- 6. Popcorn -> Héo Mòn Hoa Độc (+20 Mult ban đầu, -4 Mult sau mỗi trận cho đến khi tan biến)
    deity_floral = {
        id = "deity_floral",
        name = "Héo Mòn Hoa Độc",
        rarity = "common",
        cost = 5,
        currentMult = 20,
        desc = "+20 Mult ban đầu (giảm -4 Mult sau mỗi trận thắng)",
        lore = "Đóa hoa ngậm độc tàn lụi dần theo từng hơi thở tử thần.",
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
                    return { message = "Héo Mòn Hoa Độc đã cạn kiệt linh lực và tan biến!" }
                end
            end
            return { message = "Héo Mòn Hoa Độc tàn phai còn +" .. cur .. " Mult" }
        end,
    },

    -- 7. Golden Joker -> Thổ Phỉ Hoàng Kim (+$4 Vàng khi thắng trận)
    deity_golden = {
        id = "deity_golden",
        name = "Thổ Phỉ Hoàng Kim",
        rarity = "common",
        cost = 6,
        desc = "Nhận +$4 Vàng khi chiến thắng mỗi trận",
        lore = "Bàn tay tham lam bới móc châu báu từ những nấm mồ vô danh.",
        onRoundWin = function(game, self)
            return { addGold = 4, message = "+$4 Vàng từ Thổ Phỉ Hoàng Kim!" }
        end,
    },

    -- Delayed Gratification -> Kiên Nhẫn Thần Thụ (+ $2 mỗi Discard còn lại nếu không dùng Discard nào)
    deity_delayed_gratification = {
        id = "deity_delayed_gratification",
        name = "Kiên Nhẫn Thần Thụ",
        rarity = "uncommon",
        cost = 5,
        desc = "Nhận +$2 Vàng cho mỗi lượt Đổi bài (Discard) còn lại nếu không dùng lượt Đổi bài nào trong trận",
        lore = "Sự kiềm chế tột cùng trước cám dỗ đổi vận mang lại quả ngọt vô giá.",
        onRoundWin = function(game, self)
            local discardsUsed = (game and game.discardsUsedInCombat) or 0
            local discardsLeft = (game and game.discardsRemaining) or 0
            if discardsUsed == 0 and discardsLeft > 0 then
                local bonus = discardsLeft * 2
                return { addGold = bonus, message = "+$" .. bonus .. " từ Kiên Nhẫn (" .. discardsLeft .. " Discard chưa dùng)!" }
            end
        end,
    },

    -- Business Card -> Danh Thiếp Thương Gia (+ $2 Vàng khi lá Hoàng Gia J, Q, K ghi điểm)
    deity_business_card = {
        id = "deity_business_card",
        name = "Danh Thiếp Thương Gia",
        rarity = "common",
        cost = 4,
        desc = "Mỗi lá bài Hoàng Gia (J, Q, K) ghi điểm có 50% tỉ lệ nhận ngay +$2 Vàng",
        lore = "Mối quan hệ giao thương kín đáo mang lại nguồn tài chính dồi dào khi xuất quân.",
        onCardScored = function(card, ctx, self)
            local r = card.rank or 0
            if r == 11 or r == 12 or r == 13 then
                local roll = Rng.random(2)
                if roll == 1 then
                    return { addGold = 2, message = "+$2 Vàng (Danh Thiếp)!" }
                end
            end
        end,
    },

    -- 8. Gros Michel -> Cấm Quả Hỗn Mang (+15 Mult, 1/6 tự hủy mở khóa Bất Diệt Cổ Thụ)
    deity_sacred_fruit = {
        id = "deity_sacred_fruit",
        name = "Cấm Quả Hỗn Mang",
        rarity = "common",
        cost = 5,
        desc = "+15 Mult. Có 1/6 tỉ lệ thăng thiên sau mỗi trận (mở khóa Bất Diệt Cổ Thụ)",
        lore = "Trái cấm mang mầm mống diệt vong, chực chờ thức tỉnh cổ thụ.",
        onHandScored = function(handInfo, ctx, self)
            return { addMult = 15, message = "Cấm Quả +15 Mult!" }
        end,
        onRoundWin = function(game, self)
            local roll = Rng.random(6)
            if roll == 1 then
                if self then self.extinct = true end
                if game then game.sacredFruitExtinct = true end
                return { message = "Cấm Quả Hỗn Mang đã thức tỉnh! (Mở khóa Bất Diệt Cổ Thụ trong Shop)" }
            end
        end,
    },
    -- Cavendish -> Bất Diệt Cổ Thụ (x3.0 XMult vĩnh viễn)
    deity_eternal_tree = {
        id = "deity_eternal_tree",
        name = "Bất Diệt Cổ Thụ",
        rarity = "rare",
        cost = 8,
        requiresExtinct = "deity_sacred_fruit",
        desc = "x3.0 XMult vĩnh viễn cho mọi tay bài",
        lore = "Cây đại thụ vươn cành ôm trọn cả bầu trời sao tăm tối.",
        onHandScored = function(handInfo, ctx, self)
            return { xMult = 3.0, message = "Bất Diệt Cổ Thụ ×3.0 Mult!" }
        end,
    },

    -- 9. Card Sharp -> Vọng Âm Trùng Điệp (x3.0 XMult nếu thế bài được chơi lặp lại trong cùng trận)
    deity_echo = {
        id = "deity_echo",
        name = "Vọng Âm Trùng Điệp",
        rarity = "rare",
        cost = 7,
        desc = "x3.0 XMult nếu thế bài này đã được chơi trong trận",
        lore = "Tiếng thét từ vực thẳm vang vọng mãi không dứt qua các ván bài.",
        onHandScored = function(handInfo, ctx, self)
            local handId = handInfo.type and handInfo.type.id
            if ctx and ctx.playedHandsHistory and handId and (ctx.playedHandsHistory[handId] or 0) >= 1 then
                return { xMult = 3.0, message = "Vọng Âm ×3.0 Mult (Thế bài lặp lại)!" }
            end
        end,
    },

    -- 10. Blueprint -> Gương Hồn Phản Chiếu (Sao chép Thần bên phải)
    deity_mirror = {
        id = "deity_mirror",
        name = "Gương Hồn Phản Chiếu",
        rarity = "legendary",
        cost = 10,
        isCopyDeity = true,
        desc = "Sao chép toàn bộ kỹ năng của Hộ Linh đứng ngay bên phải nó",
        lore = "Mặt gương nứt vỡ phản chiếu bản sao quái dị của thực tại.",
    },

    -- Shop & discoverable deities
    deity_generous = {
        id = "deity_generous",
        name = "Hào Phóng Cổ Thần",
        rarity = "common",
        cost = 4,
        desc = "+50 Chips cố định vào mỗi tay bài",
        lore = "Bố thí chút sinh lực tàn tạ cho kẻ dám thách thức thần linh.",
        onHandScored = function(handInfo, ctx, self)
            return { addChips = 50, message = "+50 Chips!" }
        end,
    },
    deity_flame = {
        id = "deity_flame",
        name = "Hỏa Diệm Nộ Cuồng",
        rarity = "common",
        cost = 4,
        desc = "+6 Mult cho mọi tay bài",
        lore = "Lửa căm hờn bùng cháy thiêu rụi toàn bộ bàn bài.",
        onHandScored = function(handInfo, ctx, self)
            return { addMult = 6, message = "+6 Mult!" }
        end,
    },
    deity_pairs = {
        id = "deity_pairs",
        name = "Song Hồn Cổ Linh",
        rarity = "uncommon",
        cost = 5,
        desc = "+12 Mult nếu tay bài là Đôi hoặc Hai Đôi",
        lore = "Hai linh hồn dị dạng bị xích chặt vào nhau trong ngục tối.",
        onHandScored = function(handInfo, ctx, self)
            if handInfo.type.id == "pair" or handInfo.type.id == "two_pair" then
                return { addMult = 12, message = "Song Hồn +12 Mult!" }
            end
        end,
    },
    deity_straight = {
        id = "deity_straight",
        name = "Trường Long Cuồng Nộ",
        rarity = "uncommon",
        cost = 6,
        desc = "+100 Chips và x1.5 XMult nếu đánh ra Sảnh",
        lore = "Con rồng xương rỗng uốn mình giữa dòng chảy hỗn mang.",
        onHandScored = function(handInfo, ctx, self)
            if handInfo.type.id == "straight" or handInfo.type.id == "straight_flush" then
                return { addChips = 100, xMult = 1.5, message = "Trường Long x1.5 Mult & +100 Chips!" }
            end
        end,
    },
    deity_flush = {
        id = "deity_flush",
        name = "Thâm Uyên Hải Triều",
        rarity = "uncommon",
        cost = 6,
        desc = "+15 Mult nếu tay bài là Thùng",
        lore = "Thủy triều đen nhấn chìm mọi hy vọng vào đáy biển sâu.",
        onHandScored = function(handInfo, ctx, self)
            if handInfo.type.id == "flush" or handInfo.type.id == "straight_flush" then
                return { addMult = 15, message = "Thâm Uyên +15 Mult!" }
            end
        end,
    },
    deity_royalty = {
        id = "deity_royalty",
        name = "Huyết Mạch Vương Quyền",
        rarity = "uncommon",
        cost = 6,
        desc = "+25 Chips cho mỗi lá J, Q, K ghi điểm",
        lore = "Dòng máu quý tộc nhiễm độc chảy trong huyết quản kẻ bạo chúa.",
        onCardScored = function(card, ctx, self)
            if card.rank >= 11 and card.rank <= 13 then
                return { addChips = 25, message = "Vương Quyền +25 Chips!" }
            end
        end,
    },
    deity_ace = {
        id = "deity_ace",
        name = "Thần Khí Tuyệt Diệt",
        rarity = "rare",
        cost = 7,
        desc = "+15 Mult và x1.5 XMult khi có ít nhất một lá Át ghi điểm",
        lore = "Cổ vật cấm kỵ có thể xóa sổ cả một nền văn minh trong chớp mắt.",
        onHandScored = function(handInfo, ctx, self)
            local hasAce = false
            for _, c in ipairs(handInfo.scoringCards) do
                if c.rank == 14 then
                    hasAce = true
                    break
                end
            end
            if hasAce then
                return { addMult = 15, xMult = 1.5, message = "Tuyệt Diệt x1.5 Mult & +15 Mult!" }
            end
        end,
    },
    deity_fullhouse = {
        id = "deity_fullhouse",
        name = "Thâm Uyên Cự Thú",
        rarity = "rare",
        cost = 7,
        desc = "x2.0 XMult nếu đánh ra Cù Lũ hoặc Tứ Quý",
        lore = "Quái vật nghìn mắt thức giấc từ đáy vực sâu thẳm.",
        onHandScored = function(handInfo, ctx, self)
            if handInfo.type.id == "full_house" or handInfo.type.id == "four_of_a_kind" then
                return { xMult = 2.0, message = "Cự Thú x2.0 Mult!" }
            end
        end,
    },
    deity_clutch = {
        id = "deity_clutch",
        name = "Tử Khắc Phục Hận",
        rarity = "rare",
        cost = 7,
        desc = "x2.0 XMult ở Lượt đánh (Hand) cuối cùng của round",
        lore = "Cú đánh tuyệt vọng của kẻ sắp bước qua ngưỡng cửa tử thần.",
        onHandScored = function(handInfo, ctx, self)
            if ctx and ctx.handsRemaining == 0 then
                return { xMult = 2.0, message = "Tử Khắc x2.0 Mult!" }
            end
        end,
    },
    deity_supreme = {
        id = "deity_supreme",
        name = "Hỗn Mang Tối Thượng",
        rarity = "legendary",
        cost = 10,
        desc = "x2.0 XMult cho mọi tay bài",
        lore = "Sự hủy diệt tuyệt đối mà không một phàm nhân nào có thể chạm tới.",
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
        local j = Rng.random(i)
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
        local j = Rng.random(i)
        candidates[i], candidates[j] = candidates[j], candidates[i]
    end

    for i = 1, math.min(count, #candidates) do
        table.insert(pool, candidates[i])
    end

    return pool
end

function Deities.getMaxSlots(gameState)
    local maxSlots = 5
    local deitiesList = nil
    if gameState and gameState.deities then
        deitiesList = gameState.deities
    elseif type(gameState) == "table" and not gameState.deities then
        deitiesList = gameState
    end
    if deitiesList then
        for _, d in pairs(deitiesList) do
            if d and d.edition == "negative" then
                maxSlots = maxSlots + 1
            end
        end
    end
    return maxSlots
end

function Deities.addDeity(gameState, deity, preferredSlot)
    if not gameState.deities then
        gameState.deities = {}
    end
    local maxSlots = Deities.getMaxSlots(gameState)
    local count = Deities.getCount(gameState.deities)
    if count >= maxSlots then
        return false
    end
    -- Clone deity so instance state (such as currentMult or extinct) is isolated
    local instance = {}
    for k, v in pairs(deity) do
        instance[k] = v
    end

    if preferredSlot and preferredSlot >= 1 and preferredSlot <= maxSlots and gameState.deities[preferredSlot] == nil then
        gameState.deities[preferredSlot] = instance
        return true
    end

    for i = 1, maxSlots do
        if gameState.deities[i] == nil then
            gameState.deities[i] = instance
            return true
        end
    end
    return false
end

return Deities
