local Monster = {}

local NORMAL_NAMES = {
    { name = "Yêu Tinh Rừng Xanh", title = "Quái Rừng", desc = "Sinh vật nhỏ bé nhưng hung hăng." },
    { name = "Thạch Quỷ Nham Thạch", title = "Quái Đá", desc = "Lớp da cứng cáp tích tụ từ nham thạch." },
    { name = "Bóng Ma Đầm Lầy", title = "Âm Hồn", desc = "Lướt qua sương mù với hơi lạnh buốt giá." },
    { name = "Sói Băng Cực Bắc", title = "Dã Thú", desc = "Nanh vuốt sắc nhọn giữa cơn bão tuyết." },
    { name = "Bọ Cạp Sa Mạc", title = "Độc Trùng", desc = "Mang nọc độc làm suy yếu ý chí chiến đấu." },
    { name = "Hiệp Sĩ Xương Cổ", title = "Vong Linh", desc = "Chiến binh cổ đại canh giữ lăng mộ." },
    { name = "Phù Thủy Hắc Ám", title = "Tà Thuật", desc = "Niệm chú nguyền rủa kẻ xâm nhập." },
    { name = "Rồng Đất Cổ Đại", title = "Cự Thú", desc = "Khổng lồ với lớp vảy dày bất khả xâm phạm." },
}

local ELITE_NAMES = {
    { name = "Hắc Ám Long Kỵ Sĩ", title = "Quái Tinh Anh (Tầng 6)", desc = "Kỵ sĩ rồng hắc ám. Thưởng nhiều vàng và Trang bị quý!" },
    { name = "Huyết Quỷ Sa Mạc", title = "Quái Tinh Anh (Tầng 11)", desc = "Hút sinh lực từ bão cát. Thưởng nhiều vàng và Trang bị quý!" },
    { name = "Cự Ma Băng Giá", title = "Quái Tinh Anh (Tầng 16)", desc = "Tảng băng ngàn năm hóa thân. Thưởng nhiều vàng và Trang bị quý!" },
}

local BOSSES = {
    [5] = {
        name = "CHÚA QUỶ GAI GÓC",
        title = "TRÙM KHU VỰC 1",
        desc = "Lời nguyền Gai Độc: Giảm 1 lượt Đổi bài (Discard) của bạn!",
        debuffId = "less_discard",
        color = { 0.95, 0.25, 0.35, 1 },
        applyModifier = function(gameState)
            gameState.discardsRemaining = math.max(0, gameState.discardsRemaining - 1)
        end
    },
    [10] = {
        name = "BÁ VƯƠNG GIÁP SẮT",
        title = "TRÙM KHU VỰC 2",
        desc = "Giáp Thiết Giáp: Kháng 20% mọi sát thương nhận vào!",
        debuffId = "damage_resist",
        color = { 0.85, 0.3, 0.8, 1 },
        modifyDamage = function(damage)
            return math.floor(damage * 0.80)
        end
    },
    [20] = {
        name = "TỐI THƯỢNG MA THẦN",
        title = "TRÙM TỐI CAO (TẦNG 20)",
        desc = "Hư Vô Tận Diệt: Giảm 1 lượt Đổi bài và giới hạn tối đa 4 lá bài mỗi lượt đánh!",
        debuffId = "max_4_cards",
        color = { 1.0, 0.15, 0.15, 1 },
        applyModifier = function(gameState)
            gameState.discardsRemaining = math.max(0, gameState.discardsRemaining - 1)
        end
    },
}

Monster.DISRUPTIVE_BOSSES = {
    the_needle = {
        id = "the_needle",
        name = "CHÚA TỂ KIM NHỌN",
        title = "TRÙM: THE NEEDLE",
        desc = "Kim Nhọn Tuyệt Mạng: Chỉ có duy nhất 1 Lượt Đánh (1 Hand) cả trận!",
        debuffId = "the_needle",
        color = { 0.95, 0.25, 0.25, 1 },
        applyModifier = function(gameState)
            gameState.handsRemaining = 1
            gameState.maxHands = 1
        end,
    },
    the_water = {
        id = "the_water",
        name = "THỦY THẦN NƯỚC LŨ",
        title = "TRÙM: THE WATER",
        desc = "Nước Lũ Tối Tăm: Bắt đầu trận đấu với 0 Lượt Đổi bài (0 Discards)!",
        debuffId = "the_water",
        color = { 0.2, 0.6, 0.95, 1 },
        applyModifier = function(gameState)
            gameState.discardsRemaining = 0
        end,
    },
    the_pillar = {
        id = "the_pillar",
        name = "KẺ KHÓA PHÁI",
        title = "TRÙM: THE PILLAR",
        desc = "Khóa Phái: Vô hiệu hóa bài của một Phe (0 Chips, 0 Mult)!",
        debuffId = "the_pillar",
        color = { 0.75, 0.4, 0.9, 1 },
        applyModifier = function(gameState)
            local suit = gameState.selectedSuit or gameState.selectedFaction or "aurelia"
            gameState.monster.lockedFaction = suit
            gameState.monster.desc = "Khóa Phái: Toàn bộ bài phe " .. suit:upper() .. " bị vô hiệu hóa (0c / 0m)!"
        end,
    },
    the_hook = {
        id = "the_hook",
        name = "MA THẦN LƯỠI CÂU",
        title = "TRÙM: THE HOOK",
        desc = "Lưỡi Câu Đoạt Mệnh: Mỗi khi chơi bài, Boss tự động vứt bỏ ngẫu nhiên 2 lá trên tay!",
        debuffId = "the_hook",
        color = { 0.9, 0.5, 0.2, 1 },
    },
    the_fish = {
        id = "the_fish",
        name = "VUA BIỂN ĐÊM ĐEN",
        title = "TRÙM: THE FISH",
        desc = "Màn Đêm Vô Tận: Mọi lá bài rút lên đều bị Úp Mặt (Face-down)!",
        debuffId = "the_fish",
        color = { 0.3, 0.35, 0.55, 1 },
        applyModifier = function(gameState)
            for _, c in ipairs(gameState.hand or {}) do
                c.faceDown = true
            end
        end,
    },
    the_arm = {
        id = "the_arm",
        name = "CỰ MA BÀN TAY",
        title = "TRÙM: THE ARM",
        desc = "Bàn Tay Suy Đồi: Mỗi lượt đánh, các lá bài tính điểm bị suy đồi giảm vĩnh viễn 1 Rank!",
        debuffId = "the_arm",
        color = { 0.5, 0.8, 0.3, 1 },
    },
}

local DISRUPTIVE_KEYS = { "the_needle", "the_water", "the_pillar", "the_hook", "the_fish", "the_arm" }

-- Calculate Monster HP: Room 1 = 76 HP, each subsequent monster encounter increases HP by +50% indefinitely
function Monster.getHpByEncounter(encounterCount, isBoss, isElite)
    local n = math.max(1, encounterCount or 1)
    local baseHp = math.floor(76 * (1.5 ^ (n - 1)) + 0.5)

    if isBoss then
        return math.max(152, math.floor(baseHp * 2.0))
    elseif isElite then
        return math.max(114, math.floor(baseHp * 1.5))
    else
        return baseHp
    end
end

-- Calculate Monster Counter-Attack Power: Encounter 1 = 12 DMG
function Monster.getAttackByEncounter(encounterCount, isBoss, isElite)
    local n = math.max(1, encounterCount or 1)
    if isBoss then
        return math.min(50, 24 + math.floor((n - 1) * 3.0))
    elseif isElite then
        return math.min(40, 18 + math.floor((n - 1) * 2.0))
    else
        return math.min(30, 12 + math.floor((n - 1) * 1.5))
    end
end

function Monster.getBaseHp(round, isBoss, isElite)
    return Monster.getHpByEncounter(round, isBoss, isElite)
end

function Monster.create(round, isBossOverride, isEliteOverride, encounterCountOverride, bossKeyOverride)
    local isBoss = (isBossOverride == true)
    local isElite = (isEliteOverride == true)
    local encounterCount = encounterCountOverride or round or 1
    local hp = Monster.getHpByEncounter(encounterCount, isBoss, isElite)
    local attack = Monster.getAttackByEncounter(encounterCount, isBoss, isElite)

    local monster = {
        round = round,
        encounterCount = encounterCount,
        isBoss = isBoss,
        isElite = isElite,
        hp = hp,
        maxHp = hp,
        damageLagHp = hp,
        attack = attack,
        intent = {
            type = "attack",
            value = attack,
            label = "Tấn Công " .. attack .. " DMG",
        },
        name = "",
        title = "",
        desc = "",
        color = { 0.85, 0.25, 0.25, 1 },
        bossData = nil,
    }

    if isBoss then
        local bossTemplate = nil
        if bossKeyOverride and Monster.DISRUPTIVE_BOSSES[bossKeyOverride] then
            bossTemplate = Monster.DISRUPTIVE_BOSSES[bossKeyOverride]
        elseif round == 20 then
            -- On Floor 20, choose one of the disruptive bosses
            local dKey = DISRUPTIVE_KEYS[((encounterCount - 1) % #DISRUPTIVE_KEYS) + 1]
            bossTemplate = Monster.DISRUPTIVE_BOSSES[dKey]
        else
            bossTemplate = BOSSES[round] or Monster.DISRUPTIVE_BOSSES.the_needle
        end

        monster.name = bossTemplate.name
        monster.title = bossTemplate.title
        monster.desc = bossTemplate.desc
        monster.color = bossTemplate.color
        monster.bossData = bossTemplate
    elseif isElite then
        local eliteIdx = ((round - 1) % #ELITE_NAMES) + 1
        local tmpl = ELITE_NAMES[eliteIdx]
        monster.name = tmpl.name
        monster.title = tmpl.title
        monster.desc = tmpl.desc
        monster.color = { 0.95, 0.45, 0.2, 1 }
    else
        local nameIdx = ((round - 1) % #NORMAL_NAMES) + 1
        local tmpl = NORMAL_NAMES[nameIdx]
        monster.name = tmpl.name
        monster.title = tmpl.title
        monster.desc = tmpl.desc
        monster.color = { 0.8, 0.35, 0.25, 1 }
    end

    return monster
end

function Monster.takeDamage(monster, rawDamage)
    local actualDamage = rawDamage
    if monster.isBoss and monster.bossData and monster.bossData.modifyDamage then
        actualDamage = monster.bossData.modifyDamage(rawDamage)
    end

    monster.hp = math.max(0, monster.hp - actualDamage)
    local defeated = (monster.hp <= 0)
    return actualDamage, defeated
end

return Monster
