local Equipment = require("src.equipment")
local Poker = require("src.poker")
local Sound = require("src.sound")
local Deck = require("src.deck")

local Shop = {}

function Shop.new()
    return {
        items = {},
        rerollCost = 3,
    }
end

function Shop.refresh(shop, gameState)
    shop.items = {}
    local unlockedHands = gameState.unlockedHands or {}

    -- 1. Skill Books (Books for currently locked hands)
    local availableBooks = {}
    for handId, book in pairs(Poker.SKILL_BOOKS) do
        if not unlockedHands[handId] then
            table.insert(availableBooks, book)
        end
    end
    -- Shuffle available books
    for i = #availableBooks, 2, -1 do
        local j = math.random(i)
        availableBooks[i], availableBooks[j] = availableBooks[j], availableBooks[i]
    end

    -- Add 1 or 2 skill books
    local bookCount = math.min(2, #availableBooks)
    for i = 1, bookCount do
        local b = availableBooks[i]
        table.insert(shop.items, {
            category = "book",
            handId = b.handId,
            name = b.name,
            subtitle = "SÁCH BÍ TỊCH",
            desc = b.desc,
            cost = b.cost,
            color = b.color,
            icon = "📖",
        })
    end

    -- 2. Weapons & Equipments (1 or 2 items)
    local eq1 = Equipment.getRandomEquipment()
    table.insert(shop.items, {
        category = "equipment",
        equipment = eq1,
        name = "Trang bị: " .. eq1.name,
        subtitle = "KHẢM VÀO LÁ BÀI",
        desc = eq1.desc,
        cost = 5,
        color = eq1.color,
        icon = eq1.icon or "💎",
    })

    local eq2 = Equipment.getRandomEquipment()
    while eq2.id == eq1.id do
        eq2 = Equipment.getRandomEquipment()
    end
    table.insert(shop.items, {
        category = "equipment",
        equipment = eq2,
        name = "Trang bị: " .. eq2.name,
        subtitle = "KHẢM VÀO LÁ BÀI",
        desc = eq2.desc,
        cost = 5,
        color = eq2.color,
        icon = eq2.icon or "💎",
    })

    -- 3. Consumable Item
    table.insert(shop.items, {
        category = "consumable",
        name = "Phù Chú Tiếp Lực",
        subtitle = "VẬT PHẨM TIÊU HAO",
        desc = "Hồi phục ngay lập tức +1 Lượt Đánh (Hands) và +1 Lượt Đổi bài (Discards)!",
        cost = 3,
        color = { 0.2, 0.85, 0.5, 1 },
        icon = "✨",
        apply = function(state)
            state.handsRemaining = state.handsRemaining + 1
            state.discardsRemaining = state.discardsRemaining + 1
        end,
    })

    -- 4. Card for sale (to reinforce deck)
    local userFaction = gameState.selectedFaction or gameState.selectedSuit or "aurelia"
    local rewardCard = nil
    if math.random() < 0.5 then
        rewardCard = Deck.createRewardCard(userFaction)
    else
        -- Native faction high rank card
        local rankPool = { 9, 10, 11, 12, 13, 14 }
        local r = rankPool[math.random(#rankPool)]
        rewardCard = Deck.newCard(r, userFaction)
    end
    table.insert(shop.items, {
        category = "card",
        card = rewardCard,
        name = "Chiêu Mộ: " .. (rewardCard.roleName or "") .. " " .. rewardCard.rankName .. " " .. rewardCard.suitSymbol,
        subtitle = "CHIÊU MỘ QUÂN BÀI",
        desc = "Thêm 1 lá bài " .. (rewardCard.roleTitle or "") .. " " .. rewardCard.rankName .. rewardCard.suitSymbol .. " (+" .. rewardCard.baseChips .. " Chips, Phe " .. rewardCard.suitName .. ") vào bộ bài!",
        cost = 4,
        color = rewardCard.color,
        icon = "🃏",
    })
    
    -- 5. Offer a Healing Potion (Bình Máu Thánh)
    table.insert(shop.items, {
        category = "heal",
        name = "Bình Máu Thánh",
        subtitle = "DƯỢC LIỆU HỒI MÁU",
        desc = "Uống lập tức hồi phục +25 HP sinh lực cho nhân vật!",
        cost = 4,
        color = { 0.25, 0.85, 0.45, 1 },
        icon = "🧪",
        healAmt = 25,
    })

    -- Limit total shop items to 6 max (remove excess from the end)
    while #shop.items > 6 do
        table.remove(shop.items)
    end
end

function Shop.buyItem(shop, itemIndex, gameState)
    local item = shop.items[itemIndex]
    if not item then return false, "Vật phẩm không tồn tại!" end

    if gameState.gold < item.cost then
        return false, "Không đủ tiền vàng!"
    end

    gameState.gold = gameState.gold - item.cost
    table.remove(shop.items, itemIndex)

    if item.category == "book" then
        gameState.unlockedHands[item.handId] = true
        Sound.play("round_win")
        return true, "Đã mở khóa bí tịch: " .. item.name .. "!"

    elseif item.category == "equipment" then
        return true, "open_socketing", item.equipment

    elseif item.category == "card" then
        Deck.addCardToDeck(gameState, item.card)
        Sound.play("card_deal")
        return true, "Đã thêm lá " .. item.card.rankName .. item.card.suitSymbol .. " vào bộ bài!"

    elseif item.category == "consumable" then
        if item.apply then
            item.apply(gameState)
        end
        Sound.play("round_win")
        return true, "Đã kích hoạt Phù Chú Tiếp Lực (+1 Lượt Đánh & +1 Lượt Đổi)!"

    elseif item.category == "heal" then
        local healVal = item.healAmt or 25
        gameState.playerHp = math.min(gameState.maxPlayerHp or 100, (gameState.playerHp or 100) + healVal)
        Sound.play("round_win")
        return true, "Đã hồi phục +" .. healVal .. " HP sinh lực!"
    end

    return false, "Vật phẩm không hợp lệ"
end

function Shop.reroll(shop, gameState)
    if gameState.gold < shop.rerollCost then
        return false, "Không đủ tiền làm mới!"
    end
    gameState.gold = gameState.gold - shop.rerollCost
    Shop.refresh(shop, gameState)
    Sound.play("card_deal")
    return true
end

function Shop.sellDeity(gameState, deityIndex)
    local d = gameState.deities and gameState.deities[deityIndex]
    if not d then return false end
    local sellPrice = math.max(1, math.floor((d.cost or 4) / 2))
    gameState.gold = gameState.gold + sellPrice
    table.remove(gameState.deities, deityIndex)
    Sound.play("chip_tick")
    return true
end

function Shop.transferEquipment(sourceCard, eqIndex, targetCard)
    if not sourceCard or not targetCard then return false, "Chưa chọn đủ bài nguồn và đích!" end
    if sourceCard == targetCard then return false, "Không thể chuyển vào cùng một lá bài!" end
    if not sourceCard.equipments or not sourceCard.equipments[eqIndex] then
        return false, "Trang bị không tồn tại!"
    end
    if not targetCard.equipments then targetCard.equipments = {} end
    if #targetCard.equipments >= 5 then
        return false, "Lá bài đích đã đầy 5 ô trang bị!"
    end

    local eq = table.remove(sourceCard.equipments, eqIndex)
    table.insert(targetCard.equipments, eq)
    Sound.play("round_win")
    return true, "Đã chuyển [" .. eq.name .. "] sang Lá " .. targetCard.rankName .. targetCard.suitSymbol .. "!"
end

return Shop
