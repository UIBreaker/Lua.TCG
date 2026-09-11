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

-- Calculate Monster HP: Room 1 = 10 HP, each subsequent monster encounter increases HP by +50% indefinitely
function Monster.getHpByEncounter(encounterCount, isBoss, isElite)
    local n = math.max(1, encounterCount or 1)
    local baseHp = math.floor(10 * (1.5 ^ (n - 1)) + 0.5)

    if isBoss then
        return math.max(25, math.floor(baseHp * 2.5))
    elseif isElite then
        return math.max(15, math.floor(baseHp * 1.5))
    else
        return baseHp
    end
end

function Monster.getBaseHp(round, isBoss, isElite)
    return Monster.getHpByEncounter(round, isBoss, isElite)
end

function Monster.create(round, isBossOverride, isEliteOverride, encounterCountOverride)
    local isBoss = (isBossOverride == true)
    local isElite = (isEliteOverride == true)
    local encounterCount = encounterCountOverride or round or 1
    local hp = Monster.getHpByEncounter(encounterCount, isBoss, isElite)

    local monster = {
        round = round,
        encounterCount = encounterCount,
        isBoss = isBoss,
        isElite = isElite,
        hp = hp,
        maxHp = hp,
        damageLagHp = hp,
        name = "",
        title = "",
        desc = "",
        color = { 0.85, 0.25, 0.25, 1 },
        bossData = nil,
    }

    if isBoss then
        local bossTemplate = BOSSES[round] or BOSSES[20] or BOSSES[5]
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
