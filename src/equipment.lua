local Equipment = {}

Equipment.MAX_SLOTS = 5

Equipment.ITEMS = {
    gem_fire = {
        id = "gem_fire",
        name = "Đá Lửa",
        icon = "💎",
        color = { 0.95, 0.35, 0.2, 1 },
        desc = "+35 Chips trực tiếp cho lá bài này khi ghi điểm",
        onCardScore = function(card, playedCards, cardIndex)
            return { addChips = 35, message = "+35 Chips (Đá Lửa)" }
        end
    },
    gem_blast = {
        id = "gem_blast",
        name = "Đá Bùng Nổ",
        icon = "🔥",
        color = { 1.0, 0.5, 0.1, 1 },
        desc = "+10 Mult cho tay bài khi lá này ghi điểm",
        onCardScore = function(card, playedCards, cardIndex)
            return { addMult = 10, message = "+10 Mult (Đá Bùng Nổ)" }
        end
    },
    mirror_adjacent = {
        id = "mirror_adjacent",
        name = "Gương Lan Tỏa",
        icon = "💠",
        color = { 0.3, 0.8, 0.9, 1 },
        desc = "Buff +25 Chips cho 2 lá bài nằm cạnh lá này khi đánh ra",
        onHandEvaluate = function(card, playedCards, cardIndex)
            local buffs = {}
            if cardIndex > 1 then
                buffs[cardIndex - 1] = { addChips = 25, message = "+25 Chips (Lan tỏa)" }
            end
            if cardIndex < #playedCards then
                buffs[cardIndex + 1] = { addChips = 25, message = "+25 Chips (Lan tỏa)" }
            end
            return buffs
        end
    },
    storm_eye = {
        id = "storm_eye",
        name = "Mắt Bão",
        icon = "⚡",
        color = { 0.2, 0.9, 0.6, 1 },
        desc = "+3 Mult cho TẤT CẢ các lá bài CÙNG CHẤT với lá này trong tay bài",
        onHandEvaluate = function(card, playedCards, cardIndex)
            local buffs = {}
            for i, other in ipairs(playedCards) do
                if other.suit == card.suit then
                    buffs[i] = { addMult = 3, message = "+3 Mult (Mắt Bão)" }
                end
            end
            return buffs
        end
    },
    lucky_coin = {
        id = "lucky_coin",
        name = "Đồng Tiền May Mắn",
        icon = "💰",
        color = { 1.0, 0.85, 0.2, 1 },
        desc = "Thưởng ngay +$3 Vàng khi lá bài này được đánh ra ghi điểm",
        onCardScore = function(card, playedCards, cardIndex)
            return { addGold = 3, message = "+$3 Vàng (May Mắn)" }
        end
    },
    free_feather = {
        id = "free_feather",
        name = "Lông Vũ Tự Do",
        icon = "✨",
        color = { 0.8, 0.7, 1.0, 1 },
        desc = "Khi Đổi bài (Discard) lá này, KHÔNG bị trừ lượt đổi bài",
        onDiscard = function(card)
            return { freeDiscard = true }
        end
    },
    blood_ring = {
        id = "blood_ring",
        name = "Nhẫn Huyết Thần",
        icon = "⚔️",
        color = { 0.85, 0.1, 0.25, 1 },
        desc = "Khi lá này ghi điểm, gây thêm 15% sát thương chuẩn vào máu quái",
        onCardScore = function(card, playedCards, cardIndex)
            return { extraDamagePct = 0.15, message = "+15% Sát thương Huyết Thần!" }
        end
    },
    holy_relic = {
        id = "holy_relic",
        name = "Ngọc Bội Thánh Tích",
        icon = "👑",
        color = { 0.95, 0.8, 0.2, 1 },
        desc = "Nhân trực tiếp x1.3 XMult vào tổng điểm khi lá này ghi điểm",
        onCardScore = function(card, playedCards, cardIndex)
            return { xMult = 1.3, message = "x1.3 XMult (Thánh Tích)" }
        end
    },
}

Equipment.POOL = {
    "gem_fire",
    "gem_blast",
    "mirror_adjacent",
    "storm_eye",
    "lucky_coin",
    "free_feather",
    "blood_ring",
    "holy_relic"
}

function Equipment.getRandomEquipment()
    local idx = (love and love.math and love.math.random(#Equipment.POOL)) or math.random(#Equipment.POOL)
    local key = Equipment.POOL[idx]
    return Equipment.ITEMS[key]
end

function Equipment.attach(card, equipItem)
    if not card or not equipItem then return false, "Dữ liệu không hợp lệ" end
    card.equipments = card.equipments or {}
    if #card.equipments >= Equipment.MAX_SLOTS then
        return false, "Lá bài này đã đầy 5 ô trang bị!"
    end
    table.insert(card.equipments, equipItem)
    return true, "Đã gắn " .. equipItem.name .. " vào lá " .. card.rankName .. card.suitSymbol
end

return Equipment
