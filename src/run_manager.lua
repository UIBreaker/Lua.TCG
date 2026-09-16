local Monster = require("src.monster")
local Deities = require("src.deities")
local Deck = require("src.deck")

local RunManager = {}

-- 8 Ante per run, 3 Blinds per Ante
RunManager.MAX_ANTE = 8

-- Tag reward pool for skipping Small / Big Blinds
RunManager.TAGS = {
    {
        id = "tag_gold_bag",
        name = "Túi Vàng Cực Lớn",
        desc = "Nhận ngay +$8 Vàng vào kho bạc!",
        icon = "💰",
        color = { 0.95, 0.82, 0.22, 1 },
        apply = function(gameState)
            gameState.gold = (gameState.gold or 0) + 8
            return "+$8 Vàng từ Túi Vàng!"
        end,
    },
    {
        id = "tag_card_pack",
        name = "Gói Quân Binh Miễn Phí",
        desc = "Thêm ngay 1 lá bài quý ngẫu nhiên vào bộ bài!",
        icon = "🃏",
        color = { 0.35, 0.75, 0.95, 1 },
        apply = function(gameState)
            local userFaction = gameState.selectedFaction or gameState.selectedSuit or "aurelia"
            local card = Deck.createRewardCard(userFaction)
            Deck.addCardToDeck(gameState, card)
            return "Đã nhận lá " .. card.rankName .. (card.suitSymbol or "") .. " vào bộ bài!"
        end,
    },
    {
        id = "tag_rare_deity",
        name = "Thần Bài Giáng Trần",
        desc = "Nhận ngay 1 Thần Bài ngẫu nhiên giáng lâm trợ chiến!",
        icon = "👑",
        color = { 0.95, 0.45, 0.25, 1 },
        apply = function(gameState)
            local pool = Deities.getRandomShopPool(gameState.deities or {}, 1, gameState)
            if pool and pool[1] then
                Deities.addDeity(gameState, pool[1])
                return "Thần Bài giáng lâm: " .. pool[1].name .. "!"
            end
            return "Đã nhận phúc lành Thần Bài!"
        end,
    },
    {
        id = "tag_free_equipment",
        name = "Rương Rèn Thần Binh",
        desc = "Nhận ngay 1 món Trang Bị / Ngọc Khảm ngẫu nhiên!",
        icon = "💎",
        color = { 0.85, 0.45, 0.95, 1 },
        apply = function(gameState)
            local Equipment = require("src.equipment")
            local eq = Equipment.getRandomEquipment()
            if gameState.persistentDeck and #gameState.persistentDeck > 0 and eq then
                local targetCard = gameState.persistentDeck[1]
                Equipment.attach(targetCard, eq)
                return "Đã khảm " .. eq.name .. " vào lá " .. targetCard.rankName .. (targetCard.suitSymbol or "")
            end
            return "Đã nhận trang bị mới!"
        end,
    },
    {
        id = "tag_free_reroll",
        name = "Xúc Xắc Thần Bí (D6)",
        desc = "Shop kế tiếp nhận 2 lượt Gieo lại (Reroll) miễn phí!",
        icon = "🎲",
        color = { 0.45, 0.85, 0.45, 1 },
        apply = function(gameState)
            gameState.freeRerolls = (gameState.freeRerolls or 0) + 2
            return "+2 Lượt Reroll miễn phí cho Shop tiếp theo!"
        end,
    },
    {
        id = "tag_heal",
        name = "Bình Sinh Mệnh",
        desc = "Hồi phục ngay +30 HP sinh lực!",
        icon = "🧪",
        color = { 0.25, 0.85, 0.45, 1 },
        apply = function(gameState)
            local maxHp = gameState.maxPlayerHp or 100
            gameState.playerHp = math.min(maxHp, (gameState.playerHp or 100) + 30)
            return "Đã hồi phục +30 HP sinh lực!"
        end,
    },
}

-- Boss Debuffs pool
RunManager.BOSS_DEBUFFS = {
    -- Faction Locks
    lock_aurelia = {
        id = "lock_aurelia",
        debuffId = "lock_aurelia",
        name = "KHÓA QUANG HUY",
        title = "TRÙM: KHÓA ÁNH SÁNG",
        desc = "Quang Huy Tắt Lịm: Toàn bộ bài phe Aurelia (Ánh Sáng) bị vô hiệu hóa (0 Chips / 0 Mult)!",
        color = { 0.95, 0.82, 0.22, 1 },
        lockedFaction = "aurelia",
        applyModifier = function(gameState)
            gameState.monster.lockedFaction = "aurelia"
        end,
    },
    lock_elaris = {
        id = "lock_elaris",
        debuffId = "lock_elaris",
        name = "KHÓA SINH LINH",
        title = "TRÙM: KHÓA THIÊN NHIÊN",
        desc = "Rừng Già Khô Cạn: Toàn bộ bài phe Elaris (Thiên Nhiên) bị vô hiệu hóa (0 Chips / 0 Mult)!",
        color = { 0.25, 0.82, 0.45, 1 },
        lockedFaction = "elaris",
        applyModifier = function(gameState)
            gameState.monster.lockedFaction = "elaris"
        end,
    },
    lock_vharos = {
        id = "lock_vharos",
        debuffId = "lock_vharos",
        name = "KHÓA HẮC ÁM",
        title = "TRÙM: KHÓA BÓNG ĐÊM",
        desc = "Lửa Quỷ Đóng Băng: Toàn bộ bài phe Vharos (Hắc Ám) bị vô hiệu hóa (0 Chips / 0 Mult)!",
        color = { 0.92, 0.25, 0.35, 1 },
        lockedFaction = "vharos",
        applyModifier = function(gameState)
            gameState.monster.lockedFaction = "vharos"
        end,
    },
    lock_valoria = {
        id = "lock_valoria",
        debuffId = "lock_valoria",
        name = "KHÓA THIẾT HUYẾT",
        title = "TRÙM: KHÓA NHÂN LOẠI",
        desc = "Khí Giới Rỉ Sét: Toàn bộ bài phe Valoria (Nhân Loại) bị vô hiệu hóa (0 Chips / 0 Mult)!",
        color = { 0.35, 0.65, 0.95, 1 },
        lockedFaction = "valoria",
        applyModifier = function(gameState)
            gameState.monster.lockedFaction = "valoria"
        end,
    },

    -- Hierarchy & Rule Disruptions
    lock_royals = {
        id = "lock_royals",
        debuffId = "lock_royals",
        name = "TRẢM VƯƠNG QUAN",
        title = "TRÙM: TRẢM VƯƠNG",
        desc = "Trảm Vương: Khóa toàn bộ bài Hoàng Gia (J, Q, K - 0 Chips / 0 Mult)!",
        color = { 0.85, 0.45, 0.95, 1 },
        lockedRoyals = true,
        applyModifier = function(gameState)
            gameState.monster.lockedRoyals = true
        end,
    },
    the_needle = {
        id = "the_needle",
        debuffId = "the_needle",
        name = "CHÚA TỂ KIM NHỌN",
        title = "TRÙM: THE NEEDLE",
        desc = "Kim Nhọn Tuyệt Mạng: Chỉ có duy nhất 1 Lượt Đánh (1 Hand) cả trận!",
        color = { 0.95, 0.25, 0.25, 1 },
        applyModifier = function(gameState)
            gameState.handsRemaining = 1
            gameState.maxHands = 1
        end,
    },
    the_water = {
        id = "the_water",
        debuffId = "the_water",
        name = "THỦY THẦN NƯỚC LŨ",
        title = "TRÙM: THE WATER",
        desc = "Nước Lũ Tối Tăm: Bắt đầu trận đấu với 0 Lượt Đổi bài (0 Discards)!",
        color = { 0.2, 0.6, 0.95, 1 },
        applyModifier = function(gameState)
            gameState.discardsRemaining = 0
        end,
    },
    the_fish = {
        id = "the_fish",
        debuffId = "the_fish",
        name = "VUA BIỂN ĐÊM ĐEN",
        title = "TRÙM: THE FISH",
        desc = "Màn Đêm Vô Tận: Mọi lá bài rút lên đều bị Úp Mặt (Face-down)!",
        color = { 0.3, 0.35, 0.55, 1 },
        applyModifier = function(gameState)
            for _, c in ipairs(gameState.hand or {}) do
                c.faceDown = true
            end
        end,
    },
    the_arm = {
        id = "the_arm",
        debuffId = "the_arm",
        name = "CỰ MA BÀN TAY",
        title = "TRÙM: THE ARM",
        desc = "Bàn Tay Suy Đồi: Mỗi lượt đánh, các lá bài tính điểm bị suy đồi giảm vĩnh viễn 1 Rank!",
        color = { 0.5, 0.8, 0.3, 1 },
    },
    the_hook = {
        id = "the_hook",
        debuffId = "the_hook",
        name = "MA THẦN LƯỠI CÂU",
        title = "TRÙM: THE HOOK",
        desc = "Lưỡi Câu Đoạt Mệnh: Mỗi khi chơi bài, Boss tự động vứt bỏ ngẫu nhiên 2 lá trên tay!",
        color = { 0.9, 0.5, 0.2, 1 },
    },
    max_3_cards = {
        id = "max_3_cards",
        debuffId = "max_3_cards",
        name = "HẠN CHẾ BINH LỰC",
        title = "TRÙM: THIẾU QUÂN",
        desc = "Hạn Chế Binh Lực: Mỗi tay bài xuất trận chỉ được chọn tối đa 3 lá bài!",
        color = { 0.95, 0.55, 0.2, 1 },
        maxSelectedCards = 3,
        applyModifier = function(gameState)
            gameState.maxSelectableCards = 3
        end,
    },
}

local BOSS_KEYS = {
    "lock_aurelia", "lock_elaris", "lock_vharos", "lock_valoria",
    "lock_royals", "the_needle", "the_water", "the_fish", "the_arm", "the_hook", "max_3_cards"
}

-- HP formula:
-- Small Blind: round(76 * (1.6 ^ (Ante - 1)))
-- Big Blind: round(1.5 * Small HP)
-- Boss Blind: round(2.0 * Small HP)
function RunManager.calculateBlindHp(ante, blindType)
    local a = math.max(1, math.min(RunManager.MAX_ANTE, ante or 1))
    local smallHp = math.floor(76 * (1.6 ^ (a - 1)) + 0.5)

    if blindType == "small" then
        return smallHp
    elseif blindType == "big" then
        return math.floor(smallHp * 1.5 + 0.5)
    elseif blindType == "boss" then
        return math.floor(smallHp * 2.0 + 0.5)
    end
    return smallHp
end

-- Generate a random tag for small / big blind skip
local function getRandomTag()
    local idx = (love and love.math and love.math.random(#RunManager.TAGS)) or math.random(#RunManager.TAGS)
    return RunManager.TAGS[idx]
end

-- Generate 3 blinds for a given Ante
function RunManager.generateAnteBlinds(ante, starterFaction)
    local a = math.max(1, math.min(RunManager.MAX_ANTE, ante or 1))

    local smallHp = RunManager.calculateBlindHp(a, "small")
    local bigHp = RunManager.calculateBlindHp(a, "big")
    local bossHp = RunManager.calculateBlindHp(a, "boss")

    -- Choose a Boss Debuff
    local bKey = BOSS_KEYS[((a - 1) % #BOSS_KEYS) + 1]
    local bossDebuff = RunManager.BOSS_DEBUFFS[bKey] or RunManager.BOSS_DEBUFFS.the_needle

    local blinds = {
        {
            index = 1,
            type = "small",
            name = "Tiểu Yêu",
            title = "SMALL BLIND",
            ante = a,
            hp = smallHp,
            baseReward = 3,
            canSkip = true,
            status = "upcoming", -- "upcoming", "current", "completed", "skipped"
            tag = getRandomTag(),
            color = { 0.25, 0.65, 0.95, 1 },
            icon = "⚔️",
        },
        {
            index = 2,
            type = "big",
            name = "Đại Quái",
            title = "BIG BLIND",
            ante = a,
            hp = bigHp,
            baseReward = 4,
            canSkip = true,
            status = "upcoming",
            tag = getRandomTag(),
            color = { 0.95, 0.60, 0.20, 1 },
            icon = "👹",
        },
        {
            index = 3,
            type = "boss",
            name = bossDebuff.name,
            title = "BOSS BLIND",
            ante = a,
            hp = bossHp,
            baseReward = 5,
            canSkip = false,
            status = "upcoming",
            debuff = bossDebuff,
            color = { 0.95, 0.25, 0.35, 1 },
            icon = "👑",
        },
    }

    blinds[1].status = "current"
    return blinds
end

-- Initialize a fresh Run
function RunManager.newRun(starterFaction)
    local run = {
        faction = starterFaction or "aurelia",
        selectedFaction = starterFaction or "aurelia",
        ante = 1,
        maxAnte = RunManager.MAX_ANTE,
        currentBlindIndex = 1, -- 1: Small, 2: Big, 3: Boss
        blinds = RunManager.generateAnteBlinds(1, starterFaction),
        victory = false,
        shopsVisitedInAnte = 0,
        stats = {
            blindsWon = 0,
            blindsSkipped = 0,
            totalGoldEarned = 0,
        },
    }
    return run
end

-- Get current active blind
function RunManager.getCurrentBlind(run)
    if not run or not run.blinds then return nil end
    return run.blinds[run.currentBlindIndex]
end

-- Create Monster instance for the current Blind
function RunManager.createBlindMonster(blind, gameState)
    local isBoss = (blind.type == "boss")
    local isElite = (blind.type == "big")
    local atk = (blind.ante == 1 and blind.type == "small") and 12 or math.max(12, math.floor(blind.hp * 0.15))
    local m = {
        round = blind.ante,
        encounterCount = (blind.ante - 1) * 3 + blind.index,
        isBoss = isBoss,
        isElite = isElite,
        hp = blind.hp,
        maxHp = blind.hp,
        damageLagHp = blind.hp,
        attack = atk,
        intent = {
            type = "attack",
            value = atk,
            label = "Tấn Công " .. atk .. " DMG",
        },
        name = blind.name,
        title = blind.title .. " (ANTE " .. blind.ante .. ")",
        desc = isBoss and (blind.debuff and blind.debuff.desc or "Trùm Ma Thần đầy quyền năng!") or ("Ải " .. blind.name .. ": Mục tiêu " .. blind.hp .. " HP"),
        color = blind.color or { 0.85, 0.25, 0.25, 1 },
        bossData = blind.debuff,
    }

    if isBoss and blind.debuff then
        m.bossData = blind.debuff
    end

    return m
end

-- Skip current blind (Small / Big)
function RunManager.skipCurrentBlind(run, gameState)
    local blind = RunManager.getCurrentBlind(run)
    if not blind or not blind.canSkip then
        return false, "Ải này không thể bỏ qua!"
    end

    blind.status = "skipped"
    run.stats.blindsSkipped = run.stats.blindsSkipped + 1

    local tagMsg = ""
    if blind.tag and blind.tag.apply then
        tagMsg = blind.tag.apply(gameState)
    end

    return true, tagMsg, blind.tag
end

-- Complete current blind (on combat victory)
function RunManager.completeCurrentBlind(run)
    local blind = RunManager.getCurrentBlind(run)
    if blind then
        blind.status = "completed"
        run.stats.blindsWon = run.stats.blindsWon + 1
    end
end

-- Advance to the next Blind after leaving the Shop
-- Returns: true if game continues, false + "victory" if Ante 8 Boss defeated!
function RunManager.advanceAfterShop(run, gameState)
    if not run then return false end
    run.shopsVisitedInAnte = (run.shopsVisitedInAnte or 0) + 1

    if run.currentBlindIndex < 3 then
        run.currentBlindIndex = run.currentBlindIndex + 1
        run.blinds[run.currentBlindIndex].status = "current"
        return true, "next_blind"
    else
        -- Finished Boss Blind of the current Ante
        if run.ante >= run.maxAnte then
            run.victory = true
            return false, "victory"
        else
            run.ante = run.ante + 1
            run.currentBlindIndex = 1
            run.shopsVisitedInAnte = 0
            run.blinds = RunManager.generateAnteBlinds(run.ante, gameState and gameState.selectedFaction)
            return true, "next_ante"
        end
    end
end

return RunManager
