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

    -- Step 2: Scoring cards & their equipment
    for idx, card in ipairs(handInfo.scoringCards) do
        local cardChips = card.baseChips
        bonusChips = bonusChips + cardChips

        local cardEvent = {
            type = "card_scored",
            card = card,
            cardIndex = idx,
            addedChips = cardChips,
            addedMult = 0,
            message = card.rankName .. card.suitSymbol .. " +" .. cardChips .. " Chips"
        }

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
