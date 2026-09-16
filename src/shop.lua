local Equipment = require("src.equipment")
local Poker = require("src.poker")
local Sound = require("src.sound")
local Deck = require("src.deck")
local Deities = require("src.deities")

local Shop = {}

function Shop.new()
    return {
        items = {},
        baseRerollCost = 5,
        rerollCost = 5,
        currentPackOpening = nil,
    }
end

function Shop.resetReroll(shop)
    if not shop then return end
    shop.rerollCost = shop.baseRerollCost or 5
end

function Shop.refresh(shop, gameState)
    shop.items = {}
    local unlockedHands = gameState.unlockedHands or {}
    local userFaction = gameState.selectedFaction or gameState.selectedSuit or "aurelia"

    ----------------------------------------------------------------------------
    -- 1. UPPER SECTION CARDS (Thần Hộ Mệnh, Trang Bị Khảm, Quân Bài Tuyển Mộ)
    ----------------------------------------------------------------------------
    -- A. Thần Hộ Mệnh (Deity / Joker equivalent)
    local availableDeities = Deities.getRandomShopPool(gameState.deities, 2)
    if #availableDeities > 0 then
        local d = availableDeities[1]
        local dColor = { 0.95, 0.85, 0.35, 1 }
        if d.rarity == "rare" then dColor = { 0.95, 0.40, 0.40, 1 }
        elseif d.rarity == "uncommon" then dColor = { 0.35, 0.70, 0.95, 1 } end

        table.insert(shop.items, {
            section = "upper",
            category = "deity",
            deity = d,
            name = d.name,
            subtitle = "THẦN HỘ MỆNH",
            desc = d.desc or "+Hiệu ứng đặc biệt ván đấu",
            cost = d.cost or 5,
            rarity = d.rarity or "common",
            icon = "👑",
            color = dColor,
        })
    end

    -- B. Trang Bị Khảm (Gemstone / Weapon Equipment)
    local eq1 = Equipment.getRandomEquipment()
    table.insert(shop.items, {
        section = "upper",
        category = "equipment",
        equipment = eq1,
        name = eq1.name,
        subtitle = "TRANG BỊ KHẢM",
        desc = eq1.desc,
        cost = 5,
        icon = eq1.icon or "💎",
        color = eq1.color or { 0.95, 0.75, 0.25, 1 },
    })

    -- C. Quân Bài Chiêu Mộ (Reinforcement Card for Deck)
    local rewardCard = nil
    if math.random() < 0.5 then
        rewardCard = Deck.createRewardCard(userFaction)
    else
        local rankPool = { 9, 10, 11, 12, 13, 14 }
        local r = rankPool[math.random(#rankPool)]
        rewardCard = Deck.newCard(r, userFaction)
    end
    table.insert(shop.items, {
        section = "upper",
        category = "card",
        card = rewardCard,
        name = (rewardCard.roleTitle or "Chiến Binh") .. " " .. rewardCard.rankName .. rewardCard.suitSymbol,
        subtitle = "QUÂN BÀI",
        desc = "Thêm lá " .. (rewardCard.roleTitle or "") .. " " .. rewardCard.rankName .. rewardCard.suitSymbol .. " (+" .. rewardCard.baseChips .. " Chips, Phe " .. rewardCard.suitName .. ") vào bộ bài!",
        cost = 4,
        icon = rewardCard.suitSymbol,
        color = rewardCard.color,
    })

    ----------------------------------------------------------------------------
    -- 2. LOWER SECTION CARDS (Phiếu Ante / Voucher & Gói Bài Booster Packs)
    ----------------------------------------------------------------------------
    -- A. Left: Phiếu Ante / Sách Bí Tịch (Voucher Slot)
    local availableBooks = {}
    for handId, book in pairs(Poker.SKILL_BOOKS) do
        if not unlockedHands[handId] then
            table.insert(availableBooks, book)
        end
    end
    for i = #availableBooks, 2, -1 do
        local j = math.random(i)
        availableBooks[i], availableBooks[j] = availableBooks[j], availableBooks[i]
    end

    if #availableBooks > 0 then
        local b = availableBooks[1]
        table.insert(shop.items, {
            section = "lower_voucher",
            category = "book", -- maintains compatibility with Test 9
            handId = b.handId,
            name = b.name,
            subtitle = "PHIẾU BÍ TỊCH",
            desc = "Mở khóa vĩnh viễn tay bài: " .. b.name .. " (" .. b.desc .. ")",
            cost = 10,
            color = { 0.22, 0.72, 0.98, 1 },
            icon = "📜",
        })
    else
        -- All hands unlocked: offer permanent Ante Voucher
        local vouchers = {
            { id = "v_discount", name = "Thẻ Thành Viên", desc = "Giảm vĩnh viễn -$2 giá gieo lại (Reroll) tại mọi Shop!", cost = 10, color = { 0.35, 0.85, 0.55, 1 } },
            { id = "v_interest", name = "Sổ Tiết Kiệm", desc = "Tăng trần mức lãi từ +$5 lên +$10 mỗi ván!", cost = 10, color = { 0.95, 0.80, 0.25, 1 } },
            { id = "v_hand_plus", name = "Bùa Hảo Thủ", desc = "Tăng vĩnh viễn +1 Lượt Đánh (Max Hands) mỗi trận!", cost = 10, color = { 0.85, 0.45, 0.95, 1 } },
        }
        local v = vouchers[math.random(#vouchers)]
        table.insert(shop.items, {
            section = "lower_voucher",
            category = "voucher",
            voucherId = v.id,
            name = v.name,
            subtitle = "PHIẾU ĐẶC QUYỀN",
            desc = v.desc,
            cost = v.cost,
            color = v.color,
            icon = "🎟️",
        })
    end

    -- B. Right 1: Gói Thần Bài (Buffoon Pack) hoặc Gói Trang Bị (Arcana Pack)
    if math.random() < 0.5 then
        table.insert(shop.items, {
            section = "lower_pack",
            category = "pack",
            packType = "buffoon",
            name = "GÓI THẦN BÀI",
            subtitle = "BUFFOON PACK",
            desc = "Mở gói bao gồm 3 Thần Hộ Mệnh. Người chơi chọn 1 để sở hữu!",
            cost = 4,
            color = { 0.88, 0.35, 0.35, 1 },
            icon = "🃏",
        })
    else
        table.insert(shop.items, {
            section = "lower_pack",
            category = "pack",
            packType = "arcana",
            name = "GÓI TRANG BỊ",
            subtitle = "ARCANA PACK",
            desc = "Mở gói bao gồm 3 Trang Bị Khảm. Người chơi chọn 1 để khảm vào bài!",
            cost = 5,
            color = { 0.95, 0.75, 0.25, 1 },
            icon = "💎",
        })
    end

    -- C. Right 2: Gói Quân Bài Tiêu Chuẩn (Standard Pack) hoặc Dược Liệu Hồi Máu
    if (gameState.playerHp or 100) < 60 and math.random() < 0.6 then
        table.insert(shop.items, {
            section = "lower_pack",
            category = "heal",
            name = "BÌNH MÁU THÁNH",
            subtitle = "DƯỢC LIỆU",
            desc = "Uống lập tức hồi phục +25 HP sinh lực cho nhân vật!",
            cost = 4,
            color = { 0.25, 0.85, 0.45, 1 },
            icon = "🧪",
            healAmt = 25,
        })
    else
        table.insert(shop.items, {
            section = "lower_pack",
            category = "pack",
            packType = "standard",
            name = "GÓI QUÂN BÀI",
            subtitle = "STANDARD PACK",
            desc = "Mở gói bao gồm 3 Quân Bài cường hóa. Người chơi chọn 1 đưa vào bộ bài!",
            cost = 4,
            color = { 0.25, 0.60, 0.95, 1 },
            icon = "📦",
        })
    end
end

function Shop.buyItem(shop, itemIndex, gameState)
    local item = shop.items[itemIndex]
    if not item then return false, "Vật phẩm không tồn tại!" end

    if (gameState.gold or 0) < item.cost then
        Sound.play("cant_afford")
        return false, "Không đủ tiền vàng!"
    end

    if item.category == "deity" then
        if #(gameState.deities or {}) >= 5 then
            Sound.play("cant_afford")
            return false, "Đã đầy 5 Thần Hộ Mệnh! Hãy bán bớt thần cũ trước khi mua mới."
        end
        gameState.gold = gameState.gold - item.cost
        Deities.addDeity(gameState, item.deity)
        table.remove(shop.items, itemIndex)
        Sound.play("shop_buy")
        return true, "Đã chiêu mộ: " .. item.deity.name .. "!"

    elseif item.category == "book" then
        gameState.gold = gameState.gold - item.cost
        gameState.unlockedHands[item.handId] = true
        table.remove(shop.items, itemIndex)
        Sound.play("shop_buy")
        return true, "Đã mở khóa bí tịch: " .. item.name .. "!"

    elseif item.category == "voucher" then
        gameState.gold = gameState.gold - item.cost
        table.remove(shop.items, itemIndex)
        Sound.play("shop_buy")
        if item.voucherId == "v_discount" then
            shop.baseRerollCost = math.max(1, (shop.baseRerollCost or 5) - 2)
            shop.rerollCost = math.max(1, shop.rerollCost - 2)
        elseif item.voucherId == "v_interest" then
            gameState.maxInterest = 10
        elseif item.voucherId == "v_hand_plus" then
            gameState.maxHands = (gameState.maxHands or 4) + 1
            gameState.handsRemaining = (gameState.handsRemaining or 4) + 1
        end
        return true, "Đã kích hoạt đặc quyền: " .. item.name .. "!"

    elseif item.category == "equipment" then
        gameState.gold = gameState.gold - item.cost
        local eq = item.equipment
        table.remove(shop.items, itemIndex)
        Sound.play("shop_buy")
        return true, "open_socketing", eq

    elseif item.category == "card" then
        gameState.gold = gameState.gold - item.cost
        Deck.addCardToDeck(gameState, item.card)
        table.remove(shop.items, itemIndex)
        Sound.play("shop_buy")
        return true, "Đã thêm lá " .. item.card.rankName .. item.card.suitSymbol .. " vào bộ bài!"

    elseif item.category == "pack" then
        gameState.gold = gameState.gold - item.cost
        local pack = item
        table.remove(shop.items, itemIndex)
        Sound.play("pack_open")
        local packData = Shop.openPack(pack, gameState)
        shop.currentPackOpening = packData
        return true, "open_pack", packData

    elseif item.category == "heal" then
        gameState.gold = gameState.gold - item.cost
        local healVal = item.healAmt or 25
        gameState.playerHp = math.min(gameState.maxPlayerHp or 100, (gameState.playerHp or 100) + healVal)
        table.remove(shop.items, itemIndex)
        Sound.play("shop_buy")
        return true, "Đã hồi phục +" .. healVal .. " HP sinh lực!"

    elseif item.category == "consumable" then
        gameState.gold = gameState.gold - item.cost
        if item.apply then item.apply(gameState) end
        table.remove(shop.items, itemIndex)
        Sound.play("shop_buy")
        return true, "Đã kích hoạt Phù Chú Tiếp Lực!"
    end

    return false, "Vật phẩm không hợp lệ"
end

function Shop.openPack(packItem, gameState)
    local userFaction = gameState.selectedFaction or gameState.selectedSuit or "aurelia"
    local candidates = {}
    if packItem.packType == "buffoon" then
        candidates = Deities.getRandomShopPool(gameState.deities, 3)
    elseif packItem.packType == "standard" then
        for i = 1, 3 do
            table.insert(candidates, Deck.createRewardCard(userFaction))
        end
    elseif packItem.packType == "arcana" then
        for i = 1, 3 do
            table.insert(candidates, Equipment.getRandomEquipment())
        end
    end
    return {
        pack = packItem,
        cards = candidates,
    }
end

function Shop.choosePackCard(shop, chosenIndex, gameState)
    if not shop.currentPackOpening then return false end
    local pack = shop.currentPackOpening.pack
    local card = shop.currentPackOpening.cards and shop.currentPackOpening.cards[chosenIndex]
    if not card then return false end

    if pack.packType == "buffoon" then
        if #(gameState.deities or {}) >= 5 then
            Sound.play("cant_afford")
            return false, "Đã đầy 5 Thần Hộ Mệnh!"
        end
        Deities.addDeity(gameState, card)
        Sound.play("shop_buy")
        shop.currentPackOpening = nil
        return true, "Đã chiêu mộ: " .. card.name .. "!"

    elseif pack.packType == "standard" then
        Deck.addCardToDeck(gameState, card)
        Sound.play("shop_buy")
        shop.currentPackOpening = nil
        return true, "Đã thêm lá " .. card.rankName .. card.suitSymbol .. " vào bộ bài!"

    elseif pack.packType == "arcana" then
        Sound.play("shop_buy")
        shop.currentPackOpening = nil
        return true, "open_socketing", card
    end

    shop.currentPackOpening = nil
    return true
end

function Shop.skipPack(shop)
    shop.currentPackOpening = nil
    Sound.play("ui_click")
end

function Shop.reroll(shop, gameState)
    if gameState and (gameState.freeRerolls or 0) > 0 then
        gameState.freeRerolls = gameState.freeRerolls - 1
        Shop.refresh(shop, gameState)
        Sound.play("shop_reroll")
        return true
    end
    local cost = shop.rerollCost or 5
    if (gameState.gold or 0) < cost then
        Sound.play("cant_afford")
        return false, "Không đủ tiền làm mới!"
    end
    gameState.gold = gameState.gold - cost
    shop.rerollCost = cost + 1
    Shop.refresh(shop, gameState)
    Sound.play("shop_reroll")
    return true
end

function Shop.sellDeity(gameState, deityIndex)
    local d = gameState.deities and gameState.deities[deityIndex]
    if not d then return false end
    local sellPrice = math.max(1, math.floor((d.cost or 4) / 2))
    gameState.gold = (gameState.gold or 0) + sellPrice
    gameState.deities[deityIndex] = nil
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
