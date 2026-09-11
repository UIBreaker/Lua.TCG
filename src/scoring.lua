local Scoring = {}

--[[
Formula:
Score = (Base Chips + Bonus Chips) * (Base Mult + Bonus Mult) * (Product of XMults)
Damage to Monster = Score * (1 + Total Extra Damage Pct)
]]

function Scoring.calculate(handInfo, deities, context)
    local handType = handInfo.type
    local baseChips = handType.baseChips
    local baseMult = handType.baseMult

    local bonusChips = 0
    local bonusMult = 0
    local xMultTotal = 1.0
    local totalExtraDamagePct = 0
    local bonusGoldAwarded = 0

    local steps = {}

    -- Step 1: Base hand values
    table.insert(steps, {
        type = "base_hand",
        handName = handType.name,
        vnName = handType.vnName,
        chips = baseChips,
        mult = baseMult,
        message = handType.vnName .. " (" .. baseChips .. " Chips × " .. baseMult .. " Mult)"
    })

    -- Step 1b: Tactical Discard Buffs
    if context and context.discardBuffs then
        local db = context.discardBuffs
        local addedC = db.chips or 0
        local addedM = db.mult or 0
        local addedX = db.xMult or 1.0
        local addedDmgPct = db.bonusDamagePct or 0

        bonusChips = bonusChips + addedC
        bonusMult = bonusMult + addedM
        xMultTotal = xMultTotal * addedX
        totalExtraDamagePct = totalExtraDamagePct + addedDmgPct

        if addedC > 0 or addedM > 0 or addedX > 1.0 or addedDmgPct > 0 then
            local msgParts = {}
            if addedC > 0 then table.insert(msgParts, "+" .. addedC .. " Chips") end
            if addedM > 0 then table.insert(msgParts, "+" .. addedM .. " Mult") end
            if addedX > 1.0 then table.insert(msgParts, "x" .. string.format("%.2f", addedX) .. " XMult") end
            if addedDmgPct > 0 then table.insert(msgParts, "+" .. math.floor(addedDmgPct * 100) .. "% Sát Thương") end

            table.insert(steps, {
                type = "discard_buff_trigger",
                addedChips = addedC,
                addedMult = addedM,
                xMult = addedX,
                message = "⚡ CHIẾN THUẬT BỎ BÀI: " .. table.concat(msgParts, ", "),
            })
        end
    end

    -- Check pre-hand equipment buffs (adjacent mirror, same suit storm eye)
    local cardExternalBuffs = {} -- cardIndex -> { chips, mult }
    for i, card in ipairs(handInfo.scoringCards) do
        for _, eq in ipairs(card.equipments or {}) do
            if eq.onHandEvaluate then
                local buffs = eq.onHandEvaluate(card, handInfo.scoringCards, i)
                for targetIdx, buff in pairs(buffs or {}) do
                    cardExternalBuffs[targetIdx] = cardExternalBuffs[targetIdx] or { chips = 0, mult = 0 }
                    if buff.addChips then
                        cardExternalBuffs[targetIdx].chips = cardExternalBuffs[targetIdx].chips + buff.addChips
                        table.insert(steps, {
                            type = "equipment_trigger",
                            message = eq.name .. " -> Lá " .. targetIdx .. ": +" .. buff.addChips .. " Chips",
                            addedChips = buff.addChips,
                        })
                    end
                    if buff.addMult then
                        cardExternalBuffs[targetIdx].mult = cardExternalBuffs[targetIdx].mult + buff.addMult
                        table.insert(steps, {
                            type = "equipment_trigger",
                            message = eq.name .. " -> Lá " .. targetIdx .. ": +" .. buff.addMult .. " Mult",
                            addedMult = buff.addMult,
                        })
                    end
                end
            end
        end
    end

    -- Apply external buffs to totals
    for _, b in pairs(cardExternalBuffs) do
        bonusChips = bonusChips + b.chips
        bonusMult = bonusMult + b.mult
    end

    -- Count Soldiers (ranks 2..10) in played hand (scoringCards and unscoredCards) for Knight (J) synergy
    local soldierCount = 0
    for _, c in ipairs(handInfo.scoringCards or {}) do
        if c.rank >= 2 and c.rank <= 10 then
            soldierCount = soldierCount + 1
        end
    end
    for _, c in ipairs(handInfo.unscoredCards or {}) do
        if c.rank >= 2 and c.rank <= 10 then
            soldierCount = soldierCount + 1
        end
    end

    -- Step 2: Scoring cards, Roles, Faction Passives & Equipments
    local hasAureliaCard = false

    for idx, card in ipairs(handInfo.scoringCards) do
        local cardChips = card.baseChips
        bonusChips = bonusChips + cardChips

        local cardEvent = {
            type = "card_scored",
            card = card,
            cardIndex = idx,
            addedChips = cardChips,
            addedMult = 0,
            message = (card.roleIcon or "") .. " " .. card.rankName .. card.suitSymbol .. " +" .. cardChips .. " Chips"
        }

        -- Faction Passives per card
        if card.suit == "aurelia" or (context and context.selectedSuit == "aurelia") then
            hasAureliaCard = true
        end

        if card.suit == "vharos" then
            bonusChips = bonusChips + 40
            cardEvent.addedChips = cardEvent.addedChips + 40
            cardEvent.message = cardEvent.message .. " | 🔥 Hơi Thở Ma Quỷ (+40 Chips)"
        end

        -- Card Role Passives:
        -- J (Hiệp Sĩ): +15 Chips & +2 Mult per Soldier in the hand
        if card.rank == 11 then
            if soldierCount > 0 then
                local jChips = 15 * soldierCount
                local jMult = 2 * soldierCount
                bonusChips = bonusChips + jChips
                bonusMult = bonusMult + jMult
                cardEvent.addedChips = cardEvent.addedChips + jChips
                cardEvent.addedMult = cardEvent.addedMult + jMult
                cardEvent.message = cardEvent.message .. " | 🗡️ Cận Vệ (+" .. jChips .. " Chips, +" .. jMult .. " Mult)"
            end
        -- Q (Hoàng Hậu): x1.1 XMult & +15 Chips, +2 Mult per equipped socket
        elseif card.rank == 12 then
            xMultTotal = xMultTotal * 1.1
            local eqCount = #(card.equipments or {})
            if eqCount > 0 then
                local qChips = 15 * eqCount
                local qMult = 2 * eqCount
                bonusChips = bonusChips + qChips
                bonusMult = bonusMult + qMult
                cardEvent.addedChips = cardEvent.addedChips + qChips
                cardEvent.addedMult = cardEvent.addedMult + qMult
                cardEvent.message = cardEvent.message .. " | 👑 Hoàng Hậu (x1.1 XMult, +" .. qChips .. " Chips, +" .. qMult .. " Mult)"
            else
                cardEvent.message = cardEvent.message .. " | 👑 Hoàng Hậu (x1.1 XMult)"
            end
        -- K (Quốc Vương): Pillar of damage: +25 Chips & +5 Mult
        elseif card.rank == 13 then
            local kChips = 25
            local kMult = 5
            bonusChips = bonusChips + kChips
            bonusMult = bonusMult + kMult
            cardEvent.addedChips = cardEvent.addedChips + kChips
            cardEvent.addedMult = cardEvent.addedMult + kMult
            cardEvent.message = cardEvent.message .. " | 🏰 Quốc Vương (+" .. kChips .. " Chips, +" .. kMult .. " Mult)"
        -- A (Thần Khí): Ultimate resonance: +15 Chips
        elseif card.rank == 1 or card.rank == 14 then
            local aChips = 15
            bonusChips = bonusChips + aChips
            cardEvent.addedChips = cardEvent.addedChips + aChips
            cardEvent.message = cardEvent.message .. " | ⚡ Thần Khí (+" .. aChips .. " Chips)"
        end

        -- Check Card Equipments (onCardScore)
        for _, eq in ipairs(card.equipments or {}) do
            if eq.onCardScore then
                local res = eq.onCardScore(card, handInfo.scoringCards, idx)
                if res then
                    if res.addChips then
                        bonusChips = bonusChips + res.addChips
                        cardEvent.addedChips = cardEvent.addedChips + res.addChips
                    end
                    if res.addMult then
                        bonusMult = bonusMult + res.addMult
                        cardEvent.addedMult = cardEvent.addedMult + res.addMult
                    end
                    if res.xMult then
                        xMultTotal = xMultTotal * res.xMult
                    end
                    if res.extraDamagePct then
                        totalExtraDamagePct = totalExtraDamagePct + res.extraDamagePct
                    end
                    if res.addGold then
                        bonusGoldAwarded = bonusGoldAwarded + res.addGold
                    end
                end
            end
        end

        -- Check Deities triggered by card
        local deityTriggers = {}
        for _, deity in ipairs(deities or {}) do
            if deity.onCardScored then
                local res = deity.onCardScored(card, context)
                if res then
                    if res.addChips then
                        bonusChips = bonusChips + res.addChips
                        cardEvent.addedChips = cardEvent.addedChips + res.addChips
                    end
                    if res.addMult then
                        bonusMult = bonusMult + res.addMult
                        cardEvent.addedMult = cardEvent.addedMult + res.addMult
                    end
                    table.insert(deityTriggers, {
                        deityName = deity.name,
                        message = res.message or deity.name
                    })
                end
            end
        end
        cardEvent.deityTriggers = deityTriggers
        table.insert(steps, cardEvent)
    end

    -- Aurelia Faction Passive: Hào Quang Thánh Thiện (x1.15 XMult if hand contains Aurelia card)
    if hasAureliaCard then
        xMultTotal = xMultTotal * 1.15
        table.insert(steps, {
            type = "faction_bonus",
            message = "☀️ Hào Quang Thánh Thiện (Aurelia): ×1.15 XMult!",
            xMult = 1.15,
        })
    end

    -- Step 3: Deities hand-level triggers (+Chips, +Mult, XMult)
    for _, deity in ipairs(deities or {}) do
        if deity.onHandScored then
            local res = deity.onHandScored(handInfo, context)
            if res then
                local addedChips = res.addChips or 0
                local addedMult = res.addMult or 0
                local cardXMult = res.xMult or 1.0

                bonusChips = bonusChips + addedChips
                bonusMult = bonusMult + addedMult
                if cardXMult > 1.0 then
                    xMultTotal = xMultTotal * cardXMult
                end

                table.insert(steps, {
                    type = "deity_hand",
                    deity = deity,
                    addedChips = addedChips,
                    addedMult = addedMult,
                    xMult = cardXMult,
                    message = deity.name .. ": " .. (res.message or deity.desc)
                })
            end
        end
    end

    -- Total calculation
    local totalChips = baseChips + bonusChips
    local totalMult = baseMult + bonusMult
    local rawScore = math.floor(totalChips * totalMult * xMultTotal)
    local finalScore = math.floor(rawScore * (1 + totalExtraDamagePct))

    table.insert(steps, {
        type = "final_score",
        totalChips = totalChips,
        totalMult = totalMult,
        xMult = xMultTotal,
        rawScore = rawScore,
        extraDamagePct = totalExtraDamagePct,
        finalScore = finalScore,
        bonusGold = bonusGoldAwarded,
        message = totalChips .. " Chips × " .. totalMult .. " Mult" .. (xMultTotal > 1.0 and (" × " .. xMultTotal .. " XMult") or "") .. " = " .. finalScore .. " Sát thương!"
    })

    return {
        baseChips = baseChips,
        baseMult = baseMult,
        bonusChips = bonusChips,
        bonusMult = bonusMult,
        totalChips = totalChips,
        totalMult = totalMult,
        xMultTotal = xMultTotal,
        rawScore = rawScore,
        finalScore = finalScore,
        totalExtraDamagePct = totalExtraDamagePct,
        bonusGoldAwarded = bonusGoldAwarded,
        steps = steps
    }
end

return Scoring
