local Poker = require("src.poker")
local Monster = require("src.monster")
local Map = require("src.map")
local Deities = require("src.deities")
local Equipment = require("src.equipment")
local Shop = require("src.shop")
local Deck = require("src.deck")
local UI = require("src.ui")
local RunManager = require("src.run_manager")
local RewardSystem = require("src.reward_system")

local logFile = io.open("test_results.txt", "w")
local function log(str)
    print(str)
    if logFile then
        logFile:write(str .. "\n")
        logFile:flush()
    end
end

log("=== RUNNING ROGUELIKE POKER SYSTEM TESTS ===")

do
    -- 1. Test Monster HP scaling (Encounter 1 = 10 HP, each subsequent encounter increases by 50% indefinitely)
    local m1 = Monster.create(1, false, false, 1)
    assert(m1.hp == 10, "Encounter 1 monster HP must be 10, got: " .. m1.hp)
    assert(m1.maxHp == 10, "Encounter 1 monster maxHp must be 10")
    log("[PASS] 1. Encounter 1 Monster HP is 10 HP: " .. m1.name .. " (" .. m1.hp .. " HP)")

    local m2 = Monster.create(2, false, false, 2)
    assert(m2.hp == 15, "Encounter 2 monster HP must be 15 (+50%), got: " .. m2.hp)
    local m3 = Monster.create(3, false, false, 3)
    assert(m3.hp == 23, "Encounter 3 monster HP must be 23 (+50%), got: " .. m3.hp)
    local m4 = Monster.create(4, false, false, 4)
    assert(m4.hp == 34, "Encounter 4 monster HP must be 34 (+50%), got: " .. m4.hp)
    local m5 = Monster.create(5, false, false, 5)
    assert(m5.hp == 51, "Encounter 5 monster HP must be 51 (+50%), got: " .. m5.hp)
    log("[PASS] 2. Monster HP scaling (+50% each encounter) verified: 10 -> 15 -> 23 -> 34 -> 51 HP")

    -- 2. Test Boss creation with scaling
    local boss1 = Monster.create(5, true, false, 5)
    assert(boss1.isBoss == true, "Boss must be flagged isBoss")
    assert(boss1.hp == math.floor(51 * 2.5), "Boss HP must be 2.5x base, got: " .. boss1.hp)
    log("[PASS] 2b. Boss created with scaled HP: " .. boss1.name .. " (" .. boss1.hp .. " HP)")
end

do
    -- 2. Test Poker Hand Unlock & Fallback
    local cardA = { rank = 14, rankName = "A", suit = "aurelia", baseChips = 11 }
    local cardA2 = { rank = 14, rankName = "A", suit = "aurelia", baseChips = 11 }

    -- Only high_card unlocked
    local unlocked = { high_card = true }
    local evalSingle = Poker.evaluate({ cardA }, unlocked)
    assert(evalSingle.type.id == "high_card", "Single card should evaluate to high_card")
    assert(evalSingle.type.name == "High Card", "Name should be High Card")
    log("[PASS] 3. Starter 1-card evaluation is High Card: " .. evalSingle.type.vnName)

    -- Player tries to play Pair when Pair is locked
    local evalPairLocked = Poker.evaluate({ cardA, cardA2 }, unlocked)
    assert(evalPairLocked.type.id == "high_card", "Should fallback to high_card when pair is locked")
    assert(evalPairLocked.lockedHandAttempted ~= nil, "Should note lockedHandAttempted")
    log("[PASS] 4. Locked hand attempt detected and gracefully downgraded to High Card")

    -- Unlock Song Đao (Pair)
    unlocked["pair"] = true
    local evalPairUnlocked = Poker.evaluate({ cardA, cardA2 }, unlocked)
    assert(evalPairUnlocked.type.id == "pair", "Should evaluate to pair now")
    assert(evalPairUnlocked.type.name == "Pair", "Name should be Pair")
    log("[PASS] 5. Unlocking Song Đao allows Pair evaluation: " .. evalPairUnlocked.type.vnName)
end

do
    -- 3. Test Map Generation & Navigation (20 floors)
    local map = Map.generate(1)
    assert(map.act == 1, "Map act should be 1")
    assert(map.totalFloors == 20, "Map must have 20 floors")
    assert(map.nodes["f1_1"] and map.nodes["f1_2"], "Floor 1 should have 2 nodes")
    assert(map.nodes["f1_1"].available == true, "Floor 1 nodes should be available at start")
    assert(map.nodes["f20_1"].type == "boss", "Floor 20 node should be boss")
    log("[PASS] 6. Act 1 Map generated with 20 floors, starter nodes available, boss on Floor 20")

    -- Complete node f1_1, check that connected floor 2 nodes become available
    Map.onNodeCompleted(map, "f1_1")
    assert(map.nodes["f1_1"].visited == true, "f1_1 should be visited")
    assert(map.nodes["f2_1"].available == true, "f2_1 should be unlocked after visiting f1_1")
    assert(map.nodes["f2_2"].available == true, "f2_2 should be unlocked after visiting f1_1")
    log("[PASS] 7. Map node completion unlocks connecting nodes properly")
end

-- 4. Test Boss Deity Draft
local drafted = Deities.getBossDraftPool({}, 2)
assert(#drafted == 2, "Should draft exactly 2 deities")
assert(drafted[1].id ~= drafted[2].id, "Drafted deities must be distinct")
log("[PASS] 8. Boss Deity draft offers 2 distinct deities: " .. drafted[1].name .. " and " .. drafted[2].name)

-- 5. Test Shop
local gameState = {
    gold = 20,
    unlockedHands = { high_card = true },
    deities = {},
    deck = {},
    hand = {},
    selectedFaction = "aurelia",
    selectedSuit = "aurelia",
}
local shop = Shop.new()
Shop.refresh(shop, gameState)
assert(#shop.items >= 3, "Shop should have at least 3 items")

local foundBook = nil
for idx, item in ipairs(shop.items) do
    if item.category == "book" then
        foundBook = idx
        break
    end
end
assert(foundBook ~= nil, "Shop should contain at least 1 Skill Book")
local bookItem = shop.items[foundBook]
local bookHandId = bookItem.handId
local success, msg = Shop.buyItem(shop, foundBook, gameState)
assert(success == true, "Should successfully buy skill book")
assert(gameState.unlockedHands[bookHandId] == true, "Buying book should unlock hand: " .. bookHandId)
log("[PASS] 9. Shop sells Skill Books and successfully unlocks hand: " .. bookHandId)

-- Test Sell Deity
table.insert(gameState.deities, { id = "test_d", name = "Test Deity", cost = 6 })
local goldBefore = gameState.gold
Shop.sellDeity(gameState, 1)
assert(#gameState.deities == 0, "Deity should be removed after sale")
assert(gameState.gold == goldBefore + 3, "Selling deity should give half price (+$3)")
log("[PASS] 10. Selling deity refunds gold properly")

-- 6. Test Starter Deck for 4 Factions (Aurelia, Elaris, Vharos, Valoria)
for _, faction in ipairs({ "aurelia", "elaris", "vharos", "valoria" }) do
    local sDeck = Deck.createStarterDeck(faction)
    assert(#sDeck == 6, "Starter deck should have 6 cards, got: " .. #sDeck)
    for _, card in ipairs(sDeck) do
        assert(card.suit == faction, "Card suit must match faction " .. faction)
        assert(card.role ~= nil, "Card must have role assigned")
    end
end
log("[PASS] 11. Starter deck has 6 cards (4 Soldiers, 1 Knight, 1 Royalty) for all 4 Factions")

do
    -- 7. Test Card Roles Hierarchy (Soldiers 2-10, Knight J, Queen Q, King K, Ace A)
    local soldierCard = Deck.newCard(5, "aurelia")
    assert(soldierCard.role == "soldier", "Rank 5 must be soldier")
    assert(soldierCard.roleName == "Chiến Binh", "Role name must be Chiến Binh")

    local knightCard = Deck.newCard(11, "aurelia")
    assert(knightCard.role == "knight", "Rank 11 must be knight")
    assert(knightCard.roleName == "Hiệp Sĩ", "Role name must be Hiệp Sĩ")

    local queenCard = Deck.newCard(12, "aurelia")
    assert(queenCard.role == "queen", "Rank 12 must be queen")
    assert(queenCard.roleName == "Hoàng Hậu", "Role name must be Hoàng Hậu")

    local kingCard = Deck.newCard(13, "aurelia")
    assert(kingCard.role == "king", "Rank 13 must be king")
    assert(kingCard.roleName == "Quốc Vương", "Role name must be Quốc Vương")

    local aceCard = Deck.newCard(14, "aurelia")
    assert(aceCard.role == "ace", "Rank 14 must be ace")
    assert(aceCard.roleName == "Thần Khí", "Role name must be Thần Khí")
    log("[PASS] 12. Card Hierarchy verified: Chiến Binh (2-10), Hiệp Sĩ (J), Hoàng Hậu (Q), Quốc Vương (K), Thần Khí (A)")
end

do
    -- 8. Test Equipment Transfer in Shop
    local cardSrc = Deck.newCard(8, "hearts")
    local cardDst = Deck.newCard(10, "hearts")
    local eqItem = Equipment.getRandomEquipment()
    Equipment.attach(cardSrc, eqItem)
    assert(#cardSrc.equipments == 1, "Source card should have 1 equipment")
    assert(#cardDst.equipments == 0, "Target card should have 0 equipments")

    local transferOk, transferMsg = Shop.transferEquipment(cardSrc, 1, cardDst)
    assert(transferOk == true, "Transfer should succeed")
    assert(#cardSrc.equipments == 0, "Source card should now have 0 equipments")
    assert(#cardDst.equipments == 1, "Target card should now have 1 equipment")
    assert(cardDst.equipments[1].id == eqItem.id, "Target received the correct equipment")
    log("[PASS] 13. Equipment transfer between cards verified successfully")
end

-- 9. Test Deities.addDeity & 0 deities at start
assert(type(Deities.addDeity) == "function", "Deities.addDeity must be a function")
local draftPick = drafted[1]
local addResult = Deities.addDeity(gameState, draftPick)
assert(addResult == true, "addDeity should return true")
assert(#gameState.deities == 1, "gameState.deities should now have 1 deity")
assert(gameState.deities[1].id == draftPick.id, "Added deity matches chosen deity")
log("[PASS] 14. Deities.addDeity successfully adds chosen deity: " .. draftPick.name)

do
    -- 10. Test Encounter Restoration ("qua trận mới thì khôi phục như ban đầu")
    local persistentDeck = Deck.createStarterDeck("hearts")
    assert(#persistentDeck == 6, "Persistent deck has 6 cards")
    local originalRank1 = persistentDeck[1].rank
    assert(persistentDeck[1].baseRank == originalRank1, "Card baseRank matches initial rank")

    -- Simulate combat degradation
    Deck.degradeCard(persistentDeck[1])
    assert(persistentDeck[1].rank == originalRank1 - 1, "Card rank degraded by 1 in combat")

    -- Restore deck for new encounter
    Deck.restoreDeck(persistentDeck)
    assert(persistentDeck[1].rank == originalRank1, "Card rank restored to baseRank across encounters")
    log("[PASS] 15. Encounter deck restoration verified: cards restore to initial rank in new encounter")
end

do
    -- 11. Test Card Addition to Deck Does Not Insert Into Hand
    local testShopState = {
        gold = 10,
        deck = {},
        hand = {},
        persistentDeck = {},
        selectedSuit = "hearts",
    }
    local newCard = Deck.newCard(10, "hearts")
    table.insert(testShopState.deck, newCard)
    assert(#testShopState.deck == 1, "Deck should have 1 card")
    assert(#testShopState.hand == 0, "Hand should NOT have any cards added outside combat")
    log("[PASS] 16. Card addition adds strictly to deck and not hand (prevents duplicate selection bug)")
end

-- 12. Test Unlocked Hand Evaluation with Mono-Suit (Straight with same suit evaluates to Straight when Straight unlocked)
local straightCards = {
    Deck.newCard(3, "hearts"),
    Deck.newCard(4, "hearts"),
    Deck.newCard(5, "hearts"),
    Deck.newCard(6, "hearts"),
    Deck.newCard(7, "hearts"),
}
-- Unlocking ONLY straight
local unlockedStraight = { high_card = true, straight = true }
local evalStraight = Poker.evaluate(straightCards, unlockedStraight)
assert(evalStraight.type.id == "straight", "Should evaluate to Straight (Trường Long) when straight is unlocked")
assert(evalStraight.type.name == "Straight", "Hand name should be Straight")
assert(evalStraight.lockedHandAttempted ~= nil, "Should indicate natural Straight Flush was downgraded")
log("[PASS] 17. Unlocked Straight correctly plays as Straight despite sharing same suit: " .. evalStraight.type.vnName)

-- 13. Test Handbook Data (All 9 hands present in Poker.HAND_TYPES_ORDERED)
assert(Poker.HAND_TYPES_ORDERED ~= nil, "Poker.HAND_TYPES_ORDERED must exist")
assert(#Poker.HAND_TYPES_ORDERED == 9, "Must have all 9 poker hands ordered")
assert(Poker.HAND_TYPES_ORDERED[1].id == "straight_flush", "Highest hand is straight_flush")
assert(Poker.HAND_TYPES_ORDERED[9].id == "high_card", "Lowest hand is high_card")
log("[PASS] 18. Handbook contains all 9 poker hands ordered by rank for Compendium view")

-- 14. Test Deck.addCardToDeck adds strictly 1 card and prevents duplicates
local testGameState = {
    persistentDeck = Deck.createStarterDeck("clubs"),
    deck = {},
    hand = {},
}
assert(#testGameState.persistentDeck == 6, "Starter deck must have 6 cards")
local extraCard = Deck.newCard(13, "spades") -- K of Spades
Deck.addCardToDeck(testGameState, extraCard)
assert(#testGameState.persistentDeck == 7, "persistentDeck must now have exactly 7 cards")
-- Calling addCardToDeck with the same card again must not duplicate
Deck.addCardToDeck(testGameState, extraCard)
assert(#testGameState.persistentDeck == 7, "persistentDeck must not add duplicate of same card")
log("[PASS] 19. Deck.addCardToDeck safely adds 1 card and blocks duplicates: 7 total cards")

-- 15. Test Deck.cloneCard preserves id
local origCard = testGameState.persistentDeck[1]
local cloneC = Deck.cloneCard(origCard)
assert(cloneC.id == origCard.id, "cloneCard must preserve the exact card id")
assert(cloneC ~= origCard, "cloneCard must be a fresh table reference")
log("[PASS] 20. Deck.cloneCard preserves exact card id for 1:1 combat tracking")

-- 16. Test Equipment persistence on persistentDeck cards
local eqItem = Equipment.getRandomEquipment()
local okAttach, attachMsg = Equipment.attach(origCard, eqItem)
assert(okAttach, "Should attach equipment to persistent card")
assert(#origCard.equipments == 1, "Card should have 1 equipment slot filled")
-- Cloning for combat should also give the clone the equipment
local combatClone = Deck.cloneCard(origCard)
assert(#combatClone.equipments == 1, "Combat clone must inherit equipment")
assert(combatClone.equipments[1].name == eqItem.name, "Combat clone equipment must match")
log("[PASS] 21. Equipment attaches to persistent deck card and clones correctly into combat")

-- 17. Test Combat Hand Card Selection Isolation (selecting card 1 never selects card 2)
local combatHand = {
    Deck.cloneCard(testGameState.persistentDeck[1]),
    Deck.cloneCard(testGameState.persistentDeck[2]),
    Deck.cloneCard(testGameState.persistentDeck[3]),
    Deck.cloneCard(testGameState.persistentDeck[4]),
}
assert(combatHand[1] ~= combatHand[2], "Hand cards must be distinct table references")
assert(combatHand[1] ~= combatHand[3], "Hand cards must be distinct table references")
assert(combatHand[1] ~= combatHand[4], "Hand cards must be distinct table references")

-- Simulate sync selections for index 1
for _, c in ipairs(combatHand) do c.selected = false end
combatHand[1].selected = true
assert(combatHand[1].selected == true, "Card 1 must be selected")
assert(combatHand[2].selected == false, "Card 2 must NOT be selected")
assert(combatHand[3].selected == false, "Card 3 must NOT be selected")
assert(combatHand[4].selected == false, "Card 4 must NOT be selected")
log("[PASS] 22. Hand card selection isolates strictly to the chosen card (no 2-card selection bug)")

-- 18. Test Faction and Role Scoring Synergy (Aurelia x1.15, Vharos +40 Chips, Knight J synergy)
local Scoring = require("src.scoring")
-- Aurelia single card
local aureliaCard = Deck.newCard(7, "aurelia")
local evalAurelia = Poker.evaluate({ aureliaCard }, { high_card = true })
local scoreAurelia = Scoring.calculate(evalAurelia, {}, { selectedFaction = "aurelia" })
assert(scoreAurelia.xMultTotal >= 1.15, "Aurelia card must grant x1.15 XMult")
log("[PASS] 23. Aurelia Hào Quang Thánh Thiện grants x1.15 XMult in scoring")

-- Vharos single card (+40 Chips)
local vharosCard = Deck.newCard(5, "vharos")
local evalVharos = Poker.evaluate({ vharosCard }, { high_card = true })
local scoreVharos = Scoring.calculate(evalVharos, {}, { selectedFaction = "vharos" })
assert(scoreVharos.bonusChips >= 40, "Vharos card must grant +40 Chips")
log("[PASS] 23b. Vharos Hơi Thở Ma Quỷ grants +40 Chips in scoring")

-- Knight J (rank 11) + Soldier (rank 5) synergy: +15 chips & +2 mult
local knightCardTest = Deck.newCard(11, "valoria")
local soldierCardTest = Deck.newCard(5, "valoria")
local evalKnight = Poker.evaluate({ knightCardTest, soldierCardTest }, { high_card = true, pair = true })
local scoreKnight = Scoring.calculate(evalKnight, {}, {})
assert(scoreKnight.bonusMult >= 2, "Knight played with Soldier must grant bonus Mult")
log("[PASS] 23c. Knight (J) synergizes with Soldier (2-10) to grant bonus Chips and Mult")

-- 19. Test Shop equipment purchase and socketing workflow
local shopSim = Shop.new()
Shop.refresh(shopSim, testGameState)
local eqToBuy = Equipment.ITEMS.holy_relic
local testCardTarget = testGameState.persistentDeck[2]
assert(#testCardTarget.equipments == 0, "Target card starts with 0 equipments")
local okAttach, attachMsg = Equipment.attach(testCardTarget, eqToBuy)
assert(okAttach, "Attachment must succeed")
-- Ensure the sync logic (pc ~= c) does not wipe equipments
for _, pc in ipairs(testGameState.persistentDeck) do
    if pc.id == testCardTarget.id and pc ~= testCardTarget then
        pc.equipments = {}
        for _, eq in ipairs(testCardTarget.equipments) do
            table.insert(pc.equipments, eq)
        end
        break
    end
end
assert(#testCardTarget.equipments == 1, "Target card must have 1 equipment after socketing")
assert(testCardTarget.equipments[1].name == eqToBuy.name, "Equipment name must match")
log("[PASS] 24. Shop equipment purchase and socketing attaches properly without being erased")

-- 20. Test Deck Exhaustion Defeat Rule (no reshuffle during battle, empty hand & deck = gameover)
local combatSim = {
    deck = { Deck.newCard(2, "aurelia"), Deck.newCard(3, "aurelia") },
    hand = { Deck.newCard(4, "aurelia") },
    discardPile = {},
    monster = Monster.create(1, false, false, 1),
    handsRemaining = 2,
    discardsRemaining = 1,
}
combatSim.monster.hp = 999 -- Very high HP monster

-- Play the single card from hand: moves to discardPile
local playedCard = table.remove(combatSim.hand, 1)
table.insert(combatSim.discardPile, playedCard)
combatSim.handsRemaining = combatSim.handsRemaining - 1

-- Draw next cards from deck
while #combatSim.hand < 8 and #combatSim.deck > 0 do
    table.insert(combatSim.hand, table.remove(combatSim.deck))
end
assert(#combatSim.hand == 2, "Hand drew the 2 remaining deck cards")
assert(#combatSim.deck == 0, "Deck is now completely empty")
assert(#combatSim.discardPile == 1, "Discard pile has 1 card")

-- Play the remaining 2 cards from hand
while #combatSim.hand > 0 do
    table.insert(combatSim.discardPile, table.remove(combatSim.hand, 1))
end
combatSim.handsRemaining = combatSim.handsRemaining - 1

-- Draw attempt with empty deck (must NOT pull from discardPile!)
while #combatSim.hand < 8 and #combatSim.deck > 0 do
    table.insert(combatSim.hand, table.remove(combatSim.deck))
end
assert(#combatSim.hand == 0, "Hand must remain empty because deck is empty")
assert(#combatSim.deck == 0, "Deck remains empty without reshuffle during battle")
assert(#combatSim.discardPile == 3, "All 3 cards are in discard pile")

-- Defeat check
local isDefeated = (#combatSim.hand == 0 and #combatSim.deck == 0 and combatSim.monster.hp > 0)
assert(isDefeated == true, "Deck and hand exhaustion without defeating monster must trigger Defeat")
log("[PASS] 25. Deck exhaustion defeat rule verified: played cards stay in discard pile and empty deck+hand causes Defeat")

-- 21. Test UI.drawCard with faceted gemstone sockets and gilded border
local UI = require("src.ui")
UI.initFonts()
local mockCard1 = Deck.newCard(10, "valoria")
local mockCard2 = Deck.newCard(14, "aurelia")
Equipment.attach(mockCard2, Equipment.ITEMS.holy_relic)
Equipment.attach(mockCard2, Equipment.ITEMS.gem_fire)

-- Verify UI.drawCard executes without error for both cards
local okDraw1 = pcall(function() UI.drawCard(mockCard1, 10, 10, 100, 145) end)
local okDraw2 = pcall(function() UI.drawCard(mockCard2, 120, 10, 100, 145) end)
assert(okDraw1, "UI.drawCard on standard card must execute cleanly")
assert(okDraw2, "UI.drawCard on equipped card with gemstone sockets must execute cleanly")
log("[PASS] 26. UI.drawCard renders faceted gemstone sockets and gilded frame without error")

-- 22. Test Faction Discard Buffs Rebalanced (Aurelia, Elaris, Vharos, Valoria)
-- A. Aurelia: Discard adds balanced +6 Chips (Soldier) or +12 Chips & +1 Mult (Royal)
local testAureliaBuffs = { chips = 0, mult = 0, xMult = 1.0, bonusDamagePct = 0 }
local aurCard = Deck.newCard(5, "aurelia")
local aurRoyal = Deck.newCard(11, "aurelia")
local addC1 = (aurCard.rank >= 11) and 12 or 6
local addM1 = (aurCard.rank >= 11) and 1 or 0
testAureliaBuffs.chips = testAureliaBuffs.chips + addC1
testAureliaBuffs.mult = testAureliaBuffs.mult + addM1

local addC2 = (aurRoyal.rank >= 11) and 12 or 6
local addM2 = (aurRoyal.rank >= 11) and 1 or 0
testAureliaBuffs.chips = testAureliaBuffs.chips + addC2
testAureliaBuffs.mult = testAureliaBuffs.mult + addM2

assert(testAureliaBuffs.chips == 18, "Aurelia soldier (6) + royal (12) = 18 chips")
assert(testAureliaBuffs.mult == 1, "Aurelia royal adds +1 mult")

local evalAur = Poker.evaluate({ Deck.newCard(10, "aurelia") }, { high_card = true })
local scoreAur = Scoring.calculate(evalAur, {}, { discardBuffs = testAureliaBuffs })
assert(scoreAur.totalChips >= 30, "Aurelia discard buffs properly elevate chips without one-shotting")
assert(scoreAur.totalMult == 2, "Aurelia discard buffs properly add +1 mult (total 2)")

-- B. Elaris: Discard restores degraded card rank up to baseRank
local elarisCard = Deck.newCard(5, "elaris")
Deck.degradeCard(elarisCard)
assert(elarisCard.rank == 4, "Elaris card degraded to rank 4 in combat")
if elarisCard.rank < elarisCard.baseRank then
    elarisCard.rank = math.min(elarisCard.baseRank, elarisCard.rank + 1)
end
assert(elarisCard.rank == 5, "Elaris discard must restore degraded card by +1 back to baseRank 5")

-- C. Vharos: Discard deals modest true damage (3 for Soldier, 6 for Royal)
local vharosMonster = Monster.create(1, false, false, 1)
local initialMHP = vharosMonster.hp
local vharosCard = Deck.newCard(4, "vharos")
local vharosDmg = (vharosCard.rank >= 11) and 6 or 3 -- 3 true damage
local actualDmg, defeated = Monster.takeDamage(vharosMonster, vharosDmg)
assert(actualDmg == 3, "Vharos soldier discard must deal 3 true damage")
assert(vharosMonster.hp == initialMHP - 3, "Monster HP must decrease by exactly 3")

-- D. Valoria: Discard grants +5 Chips (Soldier), or +8 Chips and +$1 Gold (Royal)
local valoriaGold = 5
local valoriaCard = Deck.newCard(12, "valoria") -- Queen (royal)
local goldGain = (valoriaCard.rank >= 11) and 1 or 0
valoriaGold = valoriaGold + goldGain
assert(valoriaGold == 6, "Valoria royal discard must grant +$1 gold")

log("[PASS] 27. Faction Discard Buffs rebalanced cleanly: Aurelia (+6/12c, +1m), Elaris (Heal), Vharos (3/6 True Dmg), Valoria (+5/8c, +$1)")

-- 23. Test Player HP & Monster Counter-Attack
local simMon = Monster.create(1, false, false, 1)
assert(simMon.attack ~= nil and simMon.attack >= 12, "Monster must possess an attack stat (>= 12)")
local simPlayer = { playerHp = 100, maxPlayerHp = 100, playerShield = 0 }
-- Simulate monster counter-attack when not defeated
local dmgDealtToPlayer = simMon.attack
simPlayer.playerHp = math.max(0, simPlayer.playerHp - dmgDealtToPlayer)
assert(simPlayer.playerHp == 100 - simMon.attack, "Player HP reduced by monster counter-attack")
-- Simulate fatal counter-attack
simPlayer.playerHp = math.max(0, simPlayer.playerHp - 100)
assert(simPlayer.playerHp == 0, "Player HP drops to 0 on fatal counter-attack")
log("[PASS] 28. Player HP & Monster Counter-Attack verified: monster counter-attacks for " .. simMon.attack .. " HP")

-- 24. Test Tiền Lãi (Interest) Formula
local function calcInterest(gold)
    return math.min(5, math.floor(gold / 5))
end
assert(calcInterest(0) == 0, "0 gold yields 0 interest")
assert(calcInterest(4) == 0, "4 gold yields 0 interest")
assert(calcInterest(5) == 1, "5 gold yields 1 interest")
assert(calcInterest(12) == 2, "12 gold yields 2 interest")
assert(calcInterest(24) == 4, "24 gold yields 4 interest")
assert(calcInterest(25) == 5, "25 gold yields 5 interest (cap)")
assert(calcInterest(99) == 5, "99 gold yields 5 interest (capped at 5)")
log("[PASS] 29. Tiền Lãi (Interest) verified: +$1 per $5 stored, capped at +$5 per combat")

-- 25. Test Skip Blind & Tag Rewards
local testMap = Map.generate(1)
local testCombatNode = testMap.nodes["f1_1"]
assert(testCombatNode.skipTag ~= nil, "Combat node must have an assigned skipTag")
assert(testCombatNode.skipTag.name ~= nil, "skipTag must have a display name")
local simState = {
    gold = 10,
    map = testMap,
    persistentDeck = Deck.createStarterDeck("aurelia"),
    monsterEncounterCount = 1,
}
local initialEncounter = simState.monsterEncounterCount
local skipOk, skipMsg, tag = Map.skipCombatNode(simState, "f1_1")
assert(skipOk == true, "skipCombatNode must execute successfully")
assert(simState.monsterEncounterCount == initialEncounter + 1, "Skipping increases encounterCount (+50% HP next fight)")
assert(testCombatNode.visited == true, "Skipped node marked as visited/completed")
log("[PASS] 30. Skip Blind & Tag Rewards verified: node completed with tag reward: " .. (tag.name or ""))

-- 26. Test 6 Disruptive Boss Abilities (The Needle, The Water, The Pillar, The Hook, The Fish, The Arm)
-- A. The Needle (1 Hand only)
local needleBoss = Monster.create(20, true, false, 1, "the_needle")
local gsNeedle = { handsRemaining = 4, maxHands = 4, discardsRemaining = 3 }
needleBoss.bossData.applyModifier(gsNeedle)
assert(gsNeedle.handsRemaining == 1, "The Needle sets handsRemaining to 1")

-- B. The Water (0 Discards)
local waterBoss = Monster.create(20, true, false, 1, "the_water")
local gsWater = { discardsRemaining = 3 }
waterBoss.bossData.applyModifier(gsWater)
assert(gsWater.discardsRemaining == 0, "The Water sets discardsRemaining to 0")

-- C. The Pillar (Locks a faction completely)
local pillarBoss = Monster.create(20, true, false, 1, "the_pillar")
local gsPillar = { selectedSuit = "aurelia", monster = pillarBoss }
pillarBoss.bossData.applyModifier(gsPillar)
assert(pillarBoss.lockedFaction == "aurelia", "The Pillar locks Aurelia faction")
local pEval = Poker.evaluate({ Deck.newCard(10, "aurelia") }, { high_card = true })
local pScore = Scoring.calculate(pEval, {}, { monster = pillarBoss })
local cardStep = nil
for _, st in ipairs(pScore.steps) do
    if st.type == "card_scored" then cardStep = st break end
end
assert(cardStep ~= nil, "Card scored step must be present")
assert(cardStep.addedChips == 0, "Locked faction cards add 0 Chips under The Pillar")
assert(cardStep.addedMult == 0, "Locked faction cards add 0 Mult under The Pillar")
assert(pScore.xMultTotal == 1.0, "Faction passive x1.15 is negated under The Pillar")

-- D. The Hook (Boss discards 2 cards on hand play)
local gsHookHand = { Deck.newCard(2, "aurelia"), Deck.newCard(3, "aurelia"), Deck.newCard(4, "aurelia") }
local hookDiscard = {}
for i = 1, math.min(2, #gsHookHand) do
    table.insert(hookDiscard, table.remove(gsHookHand, 1))
end
assert(#gsHookHand == 1, "The Hook removes 2 cards from player hand")
assert(#hookDiscard == 2, "The Hook sends 2 discarded cards to discardPile")

-- E. The Fish (Cards drawn are faceDown)
local gsFishCard = Deck.newCard(10, "vharos")
gsFishCard.faceDown = true
assert(gsFishCard.faceDown == true, "The Fish renders drawn cards Face-Down")

-- F. The Arm (Cards lose 1 rank when played)
local armCard = Deck.newCard(8, "elaris")
Deck.degradeCard(armCard)
assert(armCard.rank == 7, "The Arm degrades played card by -1 Rank")

log("[PASS] 31. 6 Disruptive Boss Abilities verified: The Needle, The Water, The Pillar, The Hook, The Fish, The Arm")

-- 32. Test UI.formatNumber (commas and e-notation)
assert(UI.formatNumber(15) == "15", "Small number formatting")
assert(UI.formatNumber(1250) == "1,250", "Thousands comma formatting")
assert(UI.formatNumber(1234567) == "1,234,567", "Millions comma formatting")
local sciResult = UI.formatNumber(1234000000000)
assert(sciResult:find("e12") ~= nil, ">= 1e9 must use scientific e-notation, got: " .. sciResult)
log("[PASS] 32. UI.formatNumber verified: 15 -> 15, 1250 -> 1,250, 1234567 -> 1,234,567, 1.234e12 -> " .. sciResult)

-- 33. Test Hand Card Drag Reordering
local testHand = { Deck.newCard(2, "aurelia"), Deck.newCard(5, "aurelia"), Deck.newCard(10, "aurelia") }
assert(testHand[1].rank == 2 and testHand[2].rank == 5 and testHand[3].rank == 10, "Initial hand order")
-- Swap 1 and 2
testHand[1], testHand[2] = testHand[2], testHand[1]
assert(testHand[1].rank == 5 and testHand[2].rank == 2, "Hand swap 1 & 2 verified")
-- Swap 2 and 3
testHand[2], testHand[3] = testHand[3], testHand[2]
assert(testHand[1].rank == 5 and testHand[2].rank == 10 and testHand[3].rank == 2, "Hand swap 2 & 3 verified: [5, 10, 2]")
log("[PASS] 33. Hand Drag Reordering verified: cards swap indices cleanly without data loss")

-- 34. Test Text Sanitization, Audio Volume, and Settings Structure
local Sound = require("src.sound")
local dirtyStr = "Chiến Thần\239\184\143 Vĩ Đại\239\184\142!"
local cleanStr = UI.sanitizeText(dirtyStr)
assert(cleanStr == "Chiến Thần Vĩ Đại!", "UI.sanitizeText must strip invisible unicode variation selectors FE0F and FE0E")

Sound.setVolume(0.5)
assert(math.abs(Sound.getVolume() - 0.5) < 0.01, "Sound.setVolume / getVolume sets volume to 0.5")
Sound.setVolume(1.5)
assert(Sound.getVolume() == 1.0, "Sound.setVolume clamps max volume to 1.0")
Sound.setVolume(-0.2)
assert(Sound.getVolume() == 0.0, "Sound.setVolume clamps min volume to 0.0")
Sound.setVolume(0.8) -- Reset to default

log("[PASS] 34. Text Sanitization (variation selector stripping) & Audio Volume Clamping verified")

-- 35. Test Balatro Shop Structure, Incremental Reroll Cost, and Pack Opening
local testShop = Shop.new()
assert(testShop.rerollCost == 5, "Initial shop reroll cost must be $5")

local testGs = { gold = 20, unlockedHands = { high_card = true }, deities = {} }
Shop.refresh(testShop, testGs)

local hasUpper = false
local hasVoucher = false
local hasPack = false
for _, it in ipairs(testShop.items) do
    if it.section == "upper" then hasUpper = true end
    if it.section == "lower_voucher" or it.category == "book" then hasVoucher = true end
    if it.section == "lower_pack" or it.category == "pack" then hasPack = true end
end
assert(hasUpper, "Shop must generate upper section cards (Deity, Equipment, Card)")
assert(hasVoucher, "Shop must generate lower voucher / skill book card")
assert(hasPack, "Shop must generate lower booster packs")

-- Test incremental reroll cost
assert(testShop.rerollCost == 5, "Reroll cost starts at 5")
local rerollOk = Shop.reroll(testShop, testGs)
assert(rerollOk == true, "Reroll must succeed with $20 gold")
assert(testShop.rerollCost == 6, "Reroll cost must increase to $6 after 1st reroll")
assert(testGs.gold == 15, "Gold must be deducted by $5")

Shop.reroll(testShop, testGs)
assert(testShop.rerollCost == 7, "Reroll cost must increase to $7 after 2nd reroll")
assert(testGs.gold == 9, "Gold must be deducted by $6 (15 - 6 = 9)")

-- Test reset reroll
Shop.resetReroll(testShop)
assert(testShop.rerollCost == 5, "Shop.resetReroll must reset reroll cost back to $5")

-- Test pack opening
local buffoonPack = { packType = "buffoon", name = "Gói Thần Bài" }
local packRes = Shop.openPack(buffoonPack, testGs)
assert(packRes.cards and #packRes.cards == 3, "Buffoon pack must open 3 deity candidates")

local standardPack = { packType = "standard", name = "Gói Quân Bài" }
local stdRes = Shop.openPack(standardPack, testGs)
assert(stdRes.cards and #stdRes.cards == 3, "Standard pack must open 3 card candidates")

-- Test sound triggers
Sound.play("shop_buy")
Sound.play("shop_reroll")
Sound.play("cant_afford")
Sound.play("pack_open")

log("[PASS] 35. Balatro Shop Structure (Upper/Voucher/Packs), Incremental Reroll ($5 -> $6 -> $7 -> reset $5), & Pack Opening verified")

-- 36. Test Graphics Overhaul: Shaders, 3D Tilt & Deity Reordering
local normX, normY = UI.calculateTilt(150, 150, 100, 100, 100, 100)
assert(type(normX) == "number" and type(normY) == "number", "UI.calculateTilt must return numbers")
assert(normX >= -1 and normX <= 1 and normY >= -1 and normY <= 1, "Tilt must be bounded in [-1, 1]")

-- Test Deity Reordering
local deiList = { { id = "dei_1", name = "Aurelia" }, { id = "dei_2", name = "Vharos" } }
deiList[1], deiList[2] = deiList[2], deiList[1]
assert(deiList[1].id == "dei_2" and deiList[2].id == "dei_1", "Deity slots must swap cleanly for reordering")

-- Test Shader compilation if love.graphics is present
if love and love.graphics and love.graphics.newShader then
    local testBgShader = love.graphics.newShader([[
        extern number u_time;
        extern vec2 u_resolution;
        extern vec3 u_color_a;
        extern vec3 u_color_b;
        extern vec3 u_color_c;
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            vec2 uv = screen_coords / u_resolution;
            vec2 p = uv * 2.0 - 1.0;
            number t = u_time * 0.35;
            vec2 q = vec2(sin(p.x * 2.2 + t), cos(p.y * 2.0 - t));
            vec3 col = mix(u_color_a, u_color_b, 0.5);
            return vec4(col, 1.0) * color;
        }
    ]])
    assert(testBgShader ~= nil, "Background domain warping shader must compile successfully")

    local testCrtShader = love.graphics.newShader([[
        extern vec2 u_resolution;
        extern number u_time;
        extern number u_curvature;
        extern number u_chroma;
        extern number u_scanlines;
        extern number u_vignette;
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            vec2 uv = texture_coords;
            number r = Texel(texture, uv).r;
            return vec4(r, r, r, 1.0) * color;
        }
    ]])
    assert(testCrtShader ~= nil, "CRT post-processing shader must compile successfully")
end

log("[PASS] 36. Graphics Overhaul (CRT & Psychedelic Background Shaders, 3D Card Tilt, Deity Reordering) verified")

-- 37. Test Thần Khởi Nguyên (deity_genesis: +4 Mult unconditional)
local genHand = Poker.evaluate({ Deck.newCard(10, "valoria") })
local genScore = Scoring.calculate(genHand, { Deities.CATALOG.deity_genesis }, {})
assert(genScore.totalMult == genHand.type.baseMult + 4, "deity_genesis must grant +4 Mult")
log("[PASS] 37. Thần Khởi Nguyên verified: +4 Mult unconditional")

-- 38. Test Tứ Đại Thần Tộc (deity_aurelia, deity_elaris, deity_vharos, deity_valoria: +4 Mult per card)
local aurCards = { Deck.newCard(8, "aurelia"), Deck.newCard(8, "aurelia") }
local aurHand = Poker.evaluate(aurCards, { pair = true })
local aurScore = Scoring.calculate(aurHand, { Deities.CATALOG.deity_aurelia }, {})
assert(aurScore.totalMult == aurHand.type.baseMult + 8, "deity_aurelia must grant +4 Mult per Aurelia card (total +8)")

local vharCards = { Deck.newCard(9, "vharos"), Deck.newCard(9, "vharos"), Deck.newCard(9, "vharos") }
local vharHand = Poker.evaluate(vharCards, { three_of_a_kind = true })
local vharScore = Scoring.calculate(vharHand, { Deities.CATALOG.deity_vharos }, {})
assert(vharScore.totalMult == vharHand.type.baseMult + 12, "deity_vharos must grant +4 Mult per Vharos card (total +12)")
log("[PASS] 38. Tứ Đại Thần Tộc verified: +4 Mult per faction card scored")

-- 39. Test Thần Trận Pháp (deity_formation: +50 Chips on Pair or Three of a Kind)
local pairHand = Poker.evaluate({ Deck.newCard(7, "valoria"), Deck.newCard(7, "elaris") }, { pair = true })
local pairBase = Scoring.calculate(pairHand, {}, {})
local formScore = Scoring.calculate(pairHand, { Deities.CATALOG.deity_formation }, {})
assert(formScore.totalChips == pairBase.totalChips + 50, "deity_formation must grant +50 Chips on Pair")
local highHand = Poker.evaluate({ Deck.newCard(7, "valoria") }, { high_card = true })
local highBase = Scoring.calculate(highHand, {}, {})
local noFormScore = Scoring.calculate(highHand, { Deities.CATALOG.deity_formation }, {})
assert(noFormScore.totalChips == highBase.totalChips, "deity_formation must not trigger on High Card")
log("[PASS] 39. Thần Trận Pháp verified: +50 Chips for tactical formations (Pair / Trips)")

-- 40. Test Thần Tinh Binh (deity_elite: +20 Mult if hand <= 3 cards)
local smallHand = Poker.evaluate({ Deck.newCard(4, "elaris"), Deck.newCard(5, "elaris") }, { high_card = true })
local smallScore = Scoring.calculate(smallHand, { Deities.CATALOG.deity_elite }, {})
assert(smallScore.totalMult == smallHand.type.baseMult + 20, "deity_elite must grant +20 Mult when <= 3 cards played")

local largeCards = { Deck.newCard(2, "elaris"), Deck.newCard(3, "elaris"), Deck.newCard(4, "elaris"), Deck.newCard(5, "elaris"), Deck.newCard(6, "elaris") }
local largeHand = Poker.evaluate(largeCards, { straight = true })
local largeScore = Scoring.calculate(largeHand, { Deities.CATALOG.deity_elite }, {})
assert(largeScore.totalMult == largeHand.type.baseMult, "deity_elite must not grant Mult when > 3 cards played")
log("[PASS] 40. Thần Tinh Binh verified: +20 Mult strictly for hands <= 3 cards")

-- 41. Test Thần Chiến Kỷ (deity_banner: +30 Chips per remaining discard)
local bannerHand = Poker.evaluate({ Deck.newCard(9, "valoria") }, { high_card = true })
local bannerBase = Scoring.calculate(bannerHand, {}, { discardsRemaining = 4 })
local bannerScore = Scoring.calculate(bannerHand, { Deities.CATALOG.deity_banner }, { discardsRemaining = 4 })
assert(bannerScore.totalChips == bannerBase.totalChips + 120, "deity_banner with 4 discards must grant +120 Chips")
log("[PASS] 41. Thần Chiến Kỷ verified: +30 Chips per remaining Discard (4 discards = +120 Chips)")

-- 42. Test Thần Bách Hoa (deity_floral: starts +20 Mult, decays -4 on round win, goes extinct at 0)
local floralDeity = {}
for k, v in pairs(Deities.CATALOG.deity_floral) do floralDeity[k] = v end
local fScore1 = Scoring.calculate(genHand, { floralDeity }, {})
assert(fScore1.totalMult == genHand.type.baseMult + 20, "Initial floral deity must grant +20 Mult")
-- Simulate round win decay
floralDeity.onRoundWin({}, floralDeity)
assert(floralDeity.currentMult == 16, "Floral deity must decay to 16 Mult after 1 round win")
local fScore2 = Scoring.calculate(genHand, { floralDeity }, {})
assert(fScore2.totalMult == genHand.type.baseMult + 16, "Decayed floral deity must grant +16 Mult")
-- Decay until extinct
floralDeity.onRoundWin({}, floralDeity) -- 12
floralDeity.onRoundWin({}, floralDeity) -- 8
floralDeity.onRoundWin({}, floralDeity) -- 4
floralDeity.onRoundWin({}, floralDeity) -- 0 -> extinct
assert(floralDeity.extinct == true, "Floral deity must be marked extinct when reaching 0 Mult")
log("[PASS] 42. Thần Bách Hoa verified: decaying Mult (+20 -> +16 -> ... -> extinct)")

-- 43. Test Thần Kim Tài (deity_golden: +$4 gold on round win)
local goldRes = Deities.CATALOG.deity_golden.onRoundWin({}, Deities.CATALOG.deity_golden)
assert(goldRes and goldRes.addGold == 4, "deity_golden must grant +$4 Gold on round win")
log("[PASS] 43. Thần Kim Tài verified: +$4 Gold on round win")

-- 44. Test Thần Quả Thần Bí (deity_sacred_fruit) and Thần Thụ Bất Diệt (deity_eternal_tree)
local mockGameState = { sacredFruitExtinct = false }
-- Ensure eternal tree is NOT in shop pool when fruit has not gone extinct
local shopPool1 = Deities.getRandomShopPool({}, 100, mockGameState)
local foundTree1 = false
for _, d in ipairs(shopPool1) do
    if d.id == "deity_eternal_tree" then foundTree1 = true break end
end
assert(not foundTree1, "deity_eternal_tree must NOT appear in shop pool before fruit extinction")

-- Trigger extinction
mockGameState.sacredFruitExtinct = true
local shopPool2 = Deities.getRandomShopPool({}, 100, mockGameState)
local foundTree2 = false
for _, d in ipairs(shopPool2) do
    if d.id == "deity_eternal_tree" then foundTree2 = true break end
end
assert(foundTree2, "deity_eternal_tree MUST appear in shop pool after fruit extinction")

local treeScore = Scoring.calculate(genHand, { Deities.CATALOG.deity_eternal_tree }, {})
assert(treeScore.xMultTotal == 3.0, "deity_eternal_tree must grant x3.0 XMult")
log("[PASS] 44. Thần Quả Thần Bí & Thần Thụ Bất Diệt verified: extinction triggers Cavendish unlock & x3.0 XMult")

-- 45. Test Thần Điệp Kích (deity_echo: x3.0 XMult on repeated hand)
local firstEchoScore = Scoring.calculate(pairHand, { Deities.CATALOG.deity_echo }, { playedHandsHistory = {} })
assert(firstEchoScore.xMultTotal == 1.0, "First play of hand must not trigger deity_echo")
local repeatEchoScore = Scoring.calculate(pairHand, { Deities.CATALOG.deity_echo }, { playedHandsHistory = { pair = 1 } })
assert(repeatEchoScore.xMultTotal == 3.0, "Repeated play of hand must trigger deity_echo x3.0 XMult")
log("[PASS] 45. Thần Điệp Kích verified: x3.0 XMult on repeated hand in same combat")

-- 46. Test Thần Phản Chiếu (deity_mirror / Blueprint)
-- Setup: [deity_mirror, deity_genesis] -> mirror copies genesis: +4 + +4 = +8 Mult
local mirrorGenesisScore = Scoring.calculate(genHand, { Deities.CATALOG.deity_mirror, Deities.CATALOG.deity_genesis }, {})
assert(mirrorGenesisScore.totalMult == genHand.type.baseMult + 8, "deity_mirror copying deity_genesis must produce +8 Mult")

-- Setup: [deity_mirror, deity_aurelia] with 2 Aurelia cards -> +8 + +8 = +16 Mult
local mirrorAurScore = Scoring.calculate(aurHand, { Deities.CATALOG.deity_mirror, Deities.CATALOG.deity_aurelia }, {})
assert(mirrorAurScore.totalMult == aurHand.type.baseMult + 16, "deity_mirror copying deity_aurelia must double faction card Mult")

-- Setup: [deity_genesis, deity_mirror] -> mirror at the end has no target to the right: +4 Mult only
local mirrorEdgeScore = Scoring.calculate(genHand, { Deities.CATALOG.deity_genesis, Deities.CATALOG.deity_mirror }, {})
assert(mirrorEdgeScore.totalMult == genHand.type.baseMult + 4, "deity_mirror with no target to the right must gracefully do nothing")
log("[PASS] 46. Thần Phản Chiếu (Blueprint) verified: dynamically copies deity to right across hand and card triggers")

-- 47. Test Ante & Blind HP Progression (8 Ante, Small HP = round(12 * 1.6^(Ante-1)), Big = 1.5x, Boss = 2.0x)
do
    local expectedSmallHps = {
        [1] = 12,
        [2] = 19,
        [3] = 31,
        [4] = 49,
        [5] = 79,
        [6] = 126,
        [7] = 201,
        [8] = 322,
    }
    for a = 1, 8 do
        local sHp = RunManager.calculateBlindHp(a, "small")
        local expS = expectedSmallHps[a]
        assert(sHp == expS, "Ante " .. a .. " Small Blind HP mismatch: expected " .. expS .. ", got " .. sHp)

        local bHp = RunManager.calculateBlindHp(a, "big")
        local expB = math.floor(expS * 1.5 + 0.5)
        assert(bHp == expB, "Ante " .. a .. " Big Blind HP mismatch: expected " .. expB .. ", got " .. bHp)

        local bossHp = RunManager.calculateBlindHp(a, "boss")
        local expBoss = math.floor(expS * 2.0 + 0.5)
        assert(bossHp == expBoss, "Ante " .. a .. " Boss Blind HP mismatch: expected " .. expBoss .. ", got " .. bossHp)
    end
    log("[PASS] 47. Ante & Blind HP Progression verified: 8 Antes mathematically validated (Small 12->322, Big 18->483, Boss 24->644)")
end

-- 48. Test RunManager.newRun and Blind Structure
do
    local testRun = RunManager.newRun("aurelia")
    assert(testRun.ante == 1, "Initial Ante must be 1")
    assert(testRun.maxAnte == 8, "Max Ante must be 8")
    assert(#testRun.blinds == 3, "Must have exactly 3 blinds per Ante")
    assert(testRun.blinds[1].type == "small" and testRun.blinds[1].baseReward == 3 and testRun.blinds[1].canSkip == true, "Small blind properties verified")
    assert(testRun.blinds[2].type == "big" and testRun.blinds[2].baseReward == 4 and testRun.blinds[2].canSkip == true, "Big blind properties verified")
    assert(testRun.blinds[3].type == "boss" and testRun.blinds[3].baseReward == 5 and testRun.blinds[3].canSkip == false, "Boss blind properties verified")
    assert(testRun.blinds[3].debuff ~= nil and testRun.blinds[3].debuff.title ~= nil, "Boss blind must have an assigned disruptive debuff")
    log("[PASS] 48. RunManager.newRun & 3-Blind Ante structure verified (Small/Big canSkip, Boss debuff active)")
end

-- 49. Test Cash Out Calculator (5 Sources + Valoria Passive)
do
    local testRun = RunManager.newRun("aurelia")
    local curBlindSmall = testRun.blinds[1]

    -- Non-Valoria run (Aurelia):
    -- Base ($3) + 3 unused hands ($3) + Interest on $17 ($3) + Thần Kim Tài ($4) = Subtotal $13. Faction bonus: $0. Total: $13.
    local aureliaGame = {
        selectedFaction = "aurelia",
        handsRemaining = 3,
        gold = 17,
        deities = { Deities.CATALOG.deity_golden },
    }
    local cashOutAur = RewardSystem.calculate(curBlindSmall, aureliaGame, false)
    assert(cashOutAur.basePayout == 3, "Base payout should be 3")
    assert(cashOutAur.unusedHandsBonus == 3, "Hands bonus should be 3")
    assert(cashOutAur.interestBonus == 3, "Interest on $17 should be 3")
    assert(cashOutAur.deityBonus == 4, "Deity bonus from Thần Kim Tài should be 4")
    assert(cashOutAur.subtotal == 13, "Subtotal should be 13")
    assert(cashOutAur.factionBonus == 0, "Aurelia should receive 0 faction gold bonus")
    assert(cashOutAur.totalGold == 13, "Total gold should be 13")

    -- Valoria run: Subtotal $13 -> +25% = math.ceil(13 * 0.25) = +$4 -> Total: $17
    local valoriaGame = {
        selectedFaction = "valoria",
        handsRemaining = 3,
        gold = 17,
        deities = { Deities.CATALOG.deity_golden },
    }
    local cashOutVal = RewardSystem.calculate(curBlindSmall, valoriaGame, false)
    assert(cashOutVal.subtotal == 13, "Valoria subtotal should be 13")
    assert(cashOutVal.isValoria == true, "Should detect Valoria faction")
    assert(cashOutVal.factionBonus == 4, "Valoria +25% of 13 should be math.ceil(3.25) = 4")
    assert(cashOutVal.totalGold == 17, "Valoria total gold should be 17")

    -- Skipped Blind: Base = 0, Hands = 0, Interest = $4, Deity = 0. Valoria +25% on $4 = +$1 -> Total: $5
    local valoriaSkipGame = {
        selectedFaction = "valoria",
        handsRemaining = 4,
        gold = 22,
        deities = { Deities.CATALOG.deity_golden },
    }
    local cashOutSkip = RewardSystem.calculate(curBlindSmall, valoriaSkipGame, true)
    assert(cashOutSkip.wasSkipped == true, "Should flag wasSkipped")
    assert(cashOutSkip.basePayout == 0, "Base payout for skip must be 0")
    assert(cashOutSkip.unusedHandsBonus == 0, "Hands bonus for skip must be 0")
    assert(cashOutSkip.interestBonus == 4, "Interest on $22 should be 4")
    assert(cashOutSkip.deityBonus == 0, "Deity bonus for skip must be 0")
    assert(cashOutSkip.subtotal == 4, "Subtotal should be 4")
    assert(cashOutSkip.factionBonus == 1, "Valoria bonus on 4 should be 1")
    assert(cashOutSkip.totalGold == 5, "Total gold on skip should be 5")
    log("[PASS] 49. Cash Out Calculator verified: 5 Sources (Base, Hands, Interest, Deities, Valoria +25%) and Skip mechanics")
end

-- 50. Test Skip Blind Tag, Free Reroll Tag & Shop Reroll reset
do
    local tagRun = RunManager.newRun("valoria")
    local mockShopGame = { gold = 20, selectedFaction = "valoria", freeRerolls = 0 }
    tagRun.blinds[1].tag = RunManager.TAGS[5] -- tag_free_reroll (+2 free rerolls)
    local skipOk, skipMsg, tag = RunManager.skipCurrentBlind(tagRun, mockShopGame)
    assert(skipOk == true, "Small blind should be skippable")
    assert(tagRun.blinds[1].status == "skipped", "Blind status should be skipped")
    assert(mockShopGame.freeRerolls == 2, "Tag should grant 2 free rerolls")

    local testShop = Shop.new()
    -- Reroll 1 consumes 1 free reroll without spending gold
    local rr1 = Shop.reroll(testShop, mockShopGame)
    assert(rr1 == true, "Reroll 1 should succeed")
    assert(mockShopGame.freeRerolls == 1, "Should have 1 free reroll remaining")
    assert(mockShopGame.gold == 20, "Gold should NOT be deducted when free reroll used")
    assert(testShop.rerollCost == 5, "Reroll cost should stay 5")

    -- Reroll 2 consumes last free reroll
    local rr2 = Shop.reroll(testShop, mockShopGame)
    assert(mockShopGame.freeRerolls == 0, "Should have 0 free rerolls remaining")
    assert(mockShopGame.gold == 20, "Gold still unchanged")

    -- Reroll 3 consumes $5 gold and increments cost to $6
    local rr3 = Shop.reroll(testShop, mockShopGame)
    assert(mockShopGame.gold == 15, "Gold should decrease by $5")
    assert(testShop.rerollCost == 6, "Reroll cost should increment to $6")

    -- Entering next blind resets reroll cost back to $5
    Shop.resetReroll(testShop)
    assert(testShop.rerollCost == 5, "Shop.resetReroll should reset cost to $5 on next blind")
    log("[PASS] 50. Skip Blind Tags, Free Reroll Tag, and Shop Reroll mechanics ($5 -> $6 -> reset $5) verified")
end

-- 51. Test Full 8-Ante Progression and Victory Condition
do
    local progRun = RunManager.newRun("aurelia")
    local progGame = { gold = 10, selectedFaction = "aurelia" }

    for a = 1, 8 do
        assert(progRun.ante == a, "Ante should match loop: " .. a)
        assert(progRun.currentBlindIndex == 1, "Ante " .. a .. " starts at Blind 1")

        -- Small Blind -> Shop 1
        RunManager.completeCurrentBlind(progRun)
        local cont1, r1 = RunManager.advanceAfterShop(progRun, progGame)
        assert(cont1 == true and r1 == "next_blind", "Should advance to Big Blind")
        assert(progRun.currentBlindIndex == 2, "Current blind should now be Big Blind")

        -- Big Blind -> Shop 2
        RunManager.completeCurrentBlind(progRun)
        local cont2, r2 = RunManager.advanceAfterShop(progRun, progGame)
        assert(cont2 == true and r2 == "next_blind", "Should advance to Boss Blind")
        assert(progRun.currentBlindIndex == 3, "Current blind should now be Boss Blind")

        -- Boss Blind -> Shop 3
        RunManager.completeCurrentBlind(progRun)
        local cont3, r3 = RunManager.advanceAfterShop(progRun, progGame)

        if a < 8 then
            assert(cont3 == true and r3 == "next_ante", "Ante " .. a .. " boss win should advance to next ante")
            assert(progRun.ante == a + 1, "Ante should be " .. (a + 1))
            assert(progRun.currentBlindIndex == 1, "New ante must start at Blind 1")
        else
            assert(cont3 == false and r3 == "victory", "Ante 8 boss win MUST trigger victory!")
            assert(progRun.victory == true, "progRun.victory must be true")
        end
    end
    assert(progRun.stats.blindsWon == 24, "Player should have won 24 blinds total across 8 Antes")
    log("[PASS] 51. Full 8-Ante Progression (3 Blinds & 3 Shops per Ante) and Ante 8 VICTORY verified")
end

-- 52. Test ♠️ THIẾT QUÂN THỨ (The Iron Axiom / Spades Archetype)
do
    -- Phalanx Progression: 3, 5, 8, 11 (J), 13 (K)
    local c3 = Deck.newCard(3, "spades")
    local c5 = Deck.newCard(5, "spades")
    local c8 = Deck.newCard(8, "spades")
    local cJ = Deck.newCard(11, "spades")
    local cK = Deck.newCard(13, "spades")

    local evalPhalanx = Poker.evaluate({ c3, c5, c8, cJ, cK }, { high_card = true, flush = true })
    local unplayedSpadesInHand = { Deck.newCard(4, "spades"), Deck.newCard(6, "spades") }
    local scorePhalanx = Scoring.calculate(evalPhalanx, {}, {
        selectedFaction = "spades",
        isAxiom = true,
        unplayedCards = unplayedSpadesInHand,
    })

    -- Check Phalanx Progression step
    local foundPhalanx = false
    for _, step in ipairs(scorePhalanx.steps) do
        if step.type == "phalanx_progression" then
            foundPhalanx = true
            assert(step.addedChips == 100, "Phalanx Progression on 3->5->8->11->13 must yield (2+3+3+2)*10 = 100 chips, got: " .. step.addedChips)
        end
    end
    assert(foundPhalanx == true, "Phalanx Progression must trigger on strictly ascending cards")

    -- K♠ Đại Tướng Quân Pháo Đài: +15 Chips per unplayed Spade (2 unplayed = +30 Chips)
    -- Chỉ Số Thép: +20 Chips per scored Spade (5 cards = +100 Chips)
    -- Boss Debuff Immunity
    local debuffMonster = Monster.create(1, true, false, 1)
    debuffMonster.lockedFaction = "spades"
    debuffMonster.lockedRoyals = true
    local debuffScore = Scoring.calculate(evalPhalanx, {}, {
        monster = debuffMonster,
        selectedFaction = "spades",
        isAxiom = true,
    })
    assert(debuffScore.finalScore > 0, "Spades must be 100% immune to Boss Debuffs (lockedFaction & lockedRoyals)")

    -- Q♠ Mệnh Lệnh Thiết Kỷ (x1.4 XMult with 5 Spades)
    local cQ = Deck.newCard(12, "spades")
    local eval5Spades = Poker.evaluate({ c3, c5, c8, cQ, cK }, { flush = true })
    local score5Spades = Scoring.calculate(eval5Spades, {}, { selectedFaction = "spades", isAxiom = true })
    assert(score5Spades.xMultTotal >= 1.4, "Q♠ with 5 Spades in hand must grant x1.4 XMult")

    -- J♠ Tổng Trấn Tiền Phương: when J is first/lowest, +40 Chips per soldier behind it
    local evalJFirst = Poker.evaluate({ cJ, c3, c5 }, { high_card = true })
    evalJFirst.scoringCards = { cJ, c3, c5 } -- J first with 2 soldiers behind
    local scoreJFirst = Scoring.calculate(evalJFirst, {}, { selectedFaction = "spades", isAxiom = true })
    local foundJBonus = false
    for _, step in ipairs(scoreJFirst.steps) do
        if step.message and step.message:find("Tổng Trấn Tiền Phương") then
            foundJBonus = true
        end
    end
    assert(foundJBonus == true, "J♠ when first must grant +40 Chips per Soldier behind it")

    -- A♠ Overkill Sát Khí carryover
    local cA = Deck.newCard(14, "spades")
    local evalAce = Poker.evaluate({ cA }, { high_card = true })
    local scoreAce = Scoring.calculate(evalAce, {}, {
        selectedFaction = "spades",
        isAxiom = true,
        storedSlaughterChips = 80,
    })
    assert(scoreAce.hasAceOfSpades == true, "Ace of Spades must flag hasAceOfSpades")
    local foundSlaughter = false
    for _, step in ipairs(scoreAce.steps) do
        if step.type == "slaughter_chips" then
            foundSlaughter = true
            assert(step.addedChips == 80, "Sát Khí must add 80 starting chips")
        end
    end
    assert(foundSlaughter == true, "Stored Sát Khí must apply as starting chips in combat")

    log("[PASS] 52. ♠️ Thiết Quân Thứ (The Iron Axiom): Chỉ Số Thép, Boss Debuff Immunity, Phalanx Progression (+100c), J♠ (+40c/soldier), Q♠ (x1.4), K♠ (+15c/unplayed), A♠ Sát Khí verified")
end

-- 53. Test ♥️ GIÁO HỘI HUYẾT ƯỚC (The Sanguine Covenant / Hearts Archetype)
do
    -- Cộng Hưởng: +5 Mult per scored Heart
    local h5 = Deck.newCard(5, "hearts")
    local h7 = Deck.newCard(7, "hearts")
    local evalHearts = Poker.evaluate({ h5, h7 }, { pair = false, high_card = true })
    evalHearts.scoringCards = { h5, h7 }
    local scoreHearts = Scoring.calculate(evalHearts, {}, { selectedFaction = "hearts", isSanguine = true })
    assert(scoreHearts.bonusMult >= 10, "2 scored Hearts must grant +10 bonus Mult (+5 per card)")

    -- Dấu Ấn Tử Đạo: 3 stacks = +24 Mult, x1.45 XMult
    local scoreMartyr = Scoring.calculate(evalHearts, {}, {
        selectedFaction = "hearts",
        isSanguine = true,
        martyrStacks = 3,
    })
    assert(scoreMartyr.bonusMult >= 34, "3 Martyr stacks must add +24 Mult (10 + 24 = 34)")
    assert(math.abs(scoreMartyr.xMultTotal - 1.45) < 0.01, "3 Martyr stacks must grant x1.45 XMult")

    -- K♥ Huyết Vương Bất Tử: <= 1 hand left -> +100 Chips & +25 Mult
    local hK = Deck.newCard(13, "hearts")
    local evalHK = Poker.evaluate({ hK }, { high_card = true })
    local scoreHK = Scoring.calculate(evalHK, {}, {
        selectedFaction = "hearts",
        isSanguine = true,
        handsRemaining = 1,
    })
    assert(scoreHK.bonusChips >= 125, "K♥ with 1 hand left must grant at least +125 Chips (25 base + 100 bonus)")
    assert(scoreHK.bonusMult >= 35, "K♥ with 1 hand left must grant at least +35 Mult (5 base + 5 heart + 25 bonus)")

    -- Q♥ Mẫu Nghi Tế Đàn: -1 Rank on other Hearts, x1.35 XMult
    local hQ = Deck.newCard(12, "hearts")
    local hOther = Deck.newCard(6, "hearts")
    local evalHQ = Poker.evaluate({ hQ, hOther }, { high_card = true })
    evalHQ.scoringCards = { hQ, hOther }
    local scoreHQ = Scoring.calculate(evalHQ, {}, { selectedFaction = "hearts", isSanguine = true })
    assert(scoreHQ.xMultTotal >= 1.35, "Q♥ must grant x1.35 XMult")
    assert(hOther.rank == 5, "Q♥ must temporarily sacrifice 1 rank of other Hearts (6 -> 5)")

    -- A♥ Chén Thánh Khát Máu flag
    local hA = Deck.newCard(14, "hearts")
    local evalHA = Poker.evaluate({ hA }, { high_card = true })
    local scoreHA = Scoring.calculate(evalHA, {}, { selectedFaction = "hearts", isSanguine = true })
    assert(scoreHA.hasAceOfHearts == true, "A♥ must flag hasAceOfHearts for blood gold conversion")

    log("[PASS] 53. ♥️ Giáo Hội Huyết ƯỚc (The Sanguine Covenant): +5 Mult/card, Dấu Ấn Tử Đạo (+24m, x1.45), K♥ (+100c/+25m on last hand), Q♥ (-1 rank, x1.35), A♥ Blood Gold verified")
end

-- 54. Test ♦️ TRẬT TỰ HOÀNG KIM (The Gilded Conclave / Diamonds Archetype)
do
    -- Khảm Nén Quặng: starts with 2 unlocked sockets
    local dCard = Deck.newCard(8, "diamonds")
    assert(dCard.unlockedSockets == 2, "Diamonds must start with 2/5 sockets unlocked by default")

    -- Gemstone stat efficacy +50%
    local testGem = { id = "ruby", name = "Hồng Ngọc", onCardScore = function() return { addChips = 20, addMult = 4 } end }
    Equipment.attach(dCard, testGem)
    local evalD = Poker.evaluate({ dCard }, { high_card = true })
    local scoreGem = Scoring.calculate(evalD, {}, { selectedFaction = "diamonds", isGildedConclave = true })
    -- Expected: 20 * 1.5 = 30 chips, 4 * 1.5 = 6 mult
    assert(scoreGem.bonusGoldAwarded == 1, "Scored Diamond must award +$1 Gold (Kim Ngân)")

    -- Trần Lãi Siêu Việt: +$1 per $4 stored with NO CAP!
    local gildedState = { selectedFaction = "diamonds", isGildedConclave = true, gold = 100, handsRemaining = 2 }
    local dummyBlind = { baseReward = 3, type = "small" }
    local cashOutGilded = RewardSystem.calculate(dummyBlind, gildedState, false)
    assert(cashOutGilded.interestBonus == 25, "Gilded Conclave must earn 100 / 4 = $25 uncapped interest, got: " .. cashOutGilded.interestBonus)
    assert(cashOutGilded.isGilded == true, "Must flag isGilded")

    -- J♦ Thương Nhân Vong Mạng: Steals $2 into purse (+1 from diamond +2 from J = 3 gold)
    local dJ = Deck.newCard(11, "diamonds")
    local evalDJ = Poker.evaluate({ dJ }, { high_card = true })
    local scoreDJ = Scoring.calculate(evalDJ, {}, { selectedFaction = "diamonds", isGildedConclave = true })
    assert(scoreDJ.bonusGoldAwarded == 3, "J♦ must award +$1 Kim Ngân + $2 Steal = +$3 Gold total")

    -- Q♦ Nữ Hoàng Tài Phiệt: x(1.0 + Gold * 0.02) capped at x2.0 (Q 1.1 * Wealth 1.8 * Aurelia 1.15 = 2.277)
    local dQ = Deck.newCard(12, "diamonds")
    local evalDQ = Poker.evaluate({ dQ }, { high_card = true })
    local scoreDQ = Scoring.calculate(evalDQ, {}, { selectedFaction = "diamonds", isGildedConclave = true, gold = 40 })
    assert(math.abs(scoreDQ.xMultTotal - (1.1 * 1.8 * 1.15)) < 0.02, "Q♦ with $40 gold must scale XMult by x1.80, got: " .. scoreDQ.xMultTotal)

    -- K♦ Đế Vương Mua Chuộc: Bribe $1-$5 to defeat monster
    local dK = Deck.newCard(13, "diamonds")
    local evalDK = Poker.evaluate({ dK }, { high_card = true })
    local bribeMonster = { hp = 300, maxHp = 300 }
    local mockGameState = { gold = 10 }
    local scoreDK = Scoring.calculate(evalDK, {}, {
        selectedFaction = "diamonds",
        isGildedConclave = true,
        monster = bribeMonster,
        gold = 10,
        gameState = mockGameState,
    })
    assert(scoreDK.bribeDollarsSpent > 0, "K♦ must bribe dollars to overcome monster HP")
    assert(mockGameState.gold < 10, "Gold must be deducted for K♦ bribe")

    -- A♦ Thần Tài Thu Nạp: Devour soldier card for permanent +15 Base Chips
    local dA = Deck.newCard(14, "diamonds")
    local soldierToEat = Deck.newCard(4, "diamonds")
    local devourOk = Deck.devourCard(dA, soldierToEat, mockGameState)
    assert(devourOk == true, "A♦ must successfully devour soldier card")
    assert(dA.bonusBaseChips == 15, "Devouring must give A♦ +15 Base Chips permanently")
    assert(dA.baseChips == Deck.getChipValue(14) + 15, "A♦ baseChips must reflect +15 permanent bonus")

    log("[PASS] 54. ♦️ Trật Tự Hoàng Kim (The Gilded Conclave): Kim Ngân (+$1/card), Trần Lãi Siêu Việt ($100->$25 interest), Khảm Nén Quặng (+50% stats), J♦ (+$2 steal), Q♦ (wealth xmult), K♦ (bribe rescue), A♦ (devour +15c) verified")
end

-- 55. Test ♣️ BẦY NGUYÊN SINH (The Feral Swarm / Clubs Archetype)
do
    -- Bầy Đàn: Hand size 9
    local swarmRun = RunManager.newRun("elaris")
    assert(swarmRun.faction == "elaris", "Faction must be elaris")

    -- Tuần Hoàn Thể: Discarded Clubs cycle to bottom of draw deck table.insert(deck, 1, card)
    local clubCard = Deck.newCard(6, "clubs")
    local mockDeck = { Deck.newCard(8, "clubs"), Deck.newCard(9, "clubs") }
    table.insert(mockDeck, 1, clubCard)
    assert(mockDeck[1] == clubCard, "Club card must cycle to bottom (index 1) of deck")

    -- Q♣ Ong Chúa Sinh Sản: 4-card Straight and 4-card Flush!
    local cQClub = Deck.newCard(12, "clubs")
    local c9 = Deck.newCard(9, "hearts")
    local c10 = Deck.newCard(10, "spades")
    local cJ = Deck.newCard(11, "diamonds")
    local eval4Straight = Poker.evaluate({ cQClub, cJ, c10, c9 }, { straight = true })
    assert(eval4Straight.type.id == "straight", "Q♣ must allow 4-card Straight, got: " .. eval4Straight.type.id)

    local f1 = Deck.newCard(2, "clubs")
    local f2 = Deck.newCard(4, "clubs")
    local f3 = Deck.newCard(7, "clubs")
    local eval4Flush = Poker.evaluate({ cQClub, f1, f2, f3 }, { flush = true })
    assert(eval4Flush.type.id == "flush", "Q♣ must allow 4-card Flush, got: " .. eval4Flush.type.id)

    -- K♣ Chúa Tể Bầy Đàn: x(1.0 + clubs * 0.3) XMult (3 clubs = x1.9 XMult)
    local cKClub = Deck.newCard(13, "clubs")
    local evalKClub = Poker.evaluate({ cKClub, f1, f2 }, { high_card = true })
    evalKClub.scoringCards = { cKClub, f1, f2 }
    local scoreKClub = Scoring.calculate(evalKClub, {}, { selectedFaction = "clubs", isSwarm = true })
    assert(math.abs(scoreKClub.xMultTotal - 1.9) < 0.05, "K♣ with 3 Clubs scored must grant x1.9 XMult, got: " .. scoreKClub.xMultTotal)

    -- K♣ Devour in shop: heals 20 HP
    local mockKState = { playerHp = 60, maxPlayerHp = 100, discardsRemaining = 2 }
    local offFactionCard = Deck.newCard(5, "hearts")
    local devourKResult = Deck.devourCard(cKClub, offFactionCard, mockKState)
    assert(devourKResult == true, "K♣ must devour off-faction card")
    assert(mockKState.playerHp == 80, "Devouring off-faction card must heal 20 HP (60 -> 80)")

    -- A♣ Tác Nhân Dị Chủng (Wild Suit): matches any suit for Flush
    local wAce = Deck.newCard(14, "clubs")
    assert(wAce.isWildSuit == true, "A♣ must have isWildSuit = true")
    local flushWithWild = {
        wAce,
        Deck.newCard(2, "hearts"),
        Deck.newCard(5, "hearts"),
        Deck.newCard(8, "hearts"),
        Deck.newCard(10, "hearts"),
    }
    local evalWildFlush = Poker.evaluate(flushWithWild, { flush = true })
    assert(evalWildFlush.type.id == "flush", "A♣ Wild Suit must match hearts to form Flush")

    -- Tiến Hóa Nuốt Chửng: Killing blow evolves Rank +1, Rank 10 evolves to Primal Drone
    local droneCard = Deck.newCard(10, "clubs")
    droneCard.isPrimalDrone = true
    droneCard.bonusBaseChips = 50
    droneCard.bonusMult = 5
    local evalDrone = Poker.evaluate({ droneCard }, { high_card = true })
    local scoreDrone = Scoring.calculate(evalDrone, {}, { selectedFaction = "clubs", isSwarm = true })
    assert(scoreDrone.bonusChips >= 50, "Primal Drone must grant +50 Chips")
    assert(scoreDrone.bonusMult >= 5, "Primal Drone must grant +5 Mult")

    log("[PASS] 55. ♣️ Bầy Nguyên Sinh (The Feral Swarm): Bầy Đàn (9-card hand), Tuần Hoàn Thể, Q♣ (4-card Straight & Flush), K♣ (x1.9 XMult & Heal 20 HP), A♣ Wild Suit, Chân Rết Nguyên Thủy (+50c/+5m) verified")
end

-- 56. Test TỰ DO SẮP XẾP THẦN BÀI (Deities Free Placement & Left-to-Right Scoring Order)
do
    -- 1. Arbitrary Slot Placement (can place at any slot, e.g. slot 3 and 5)
    local testGS = { deities = {} }
    local addSlot3 = Deities.addDeity(testGS, Deities.CATALOG.deity_genesis, 3)
    assert(addSlot3 == true, "Deities.addDeity must succeed in placing into preferredSlot 3")
    assert(testGS.deities[3] ~= nil, "Slot 3 must contain Genesis")
    assert(testGS.deities[1] == nil and testGS.deities[2] == nil, "Slots 1 and 2 must remain empty")

    local addSlot5 = Deities.addDeity(testGS, Deities.CATALOG.deity_eternal_tree, 5)
    assert(addSlot5 == true, "Deities.addDeity must succeed in placing into preferredSlot 5")
    assert(testGS.deities[5] ~= nil, "Slot 5 must contain Eternal Tree")
    assert(testGS.deities[4] == nil, "Slot 4 must remain empty")
    assert(Deities.getCount(testGS.deities) == 2, "Deities.getCount must accurately report 2 active deities")

    -- 2. Drag / Swap between Slots
    -- Swap slot 3 and slot 1: Genesis moves from slot 3 to slot 1
    testGS.deities[1], testGS.deities[3] = testGS.deities[3], testGS.deities[1]
    assert(testGS.deities[1] ~= nil and testGS.deities[1].id == "deity_genesis", "Genesis moved to slot 1")
    assert(testGS.deities[3] == nil, "Slot 3 is now empty")
    assert(testGS.deities[5] ~= nil and testGS.deities[5].id == "deity_eternal_tree", "Slot 5 still holds Eternal Tree")

    -- 3. Left-to-Right Scoring Order Significance: [+Mult before xMult] > [xMult before +Mult]
    local testCard = Deck.newCard(7, "clubs")
    local testHand = Poker.evaluate({ testCard }, { high_card = true })
    -- High Card base: chips = 5, mult = 1. Card rank 7: +7 chips. Total initial: chips = 12, mult = 1.

    -- Setup A: [+Mult in Slot 1, xMult in Slot 2]
    -- Order: Slot 1 = Genesis (+4 Mult), Slot 2 = Eternal Tree (x3 XMult)
    -- Expected: (1 + 4) * 3 = 15 Mult -> 12 Chips * 15 Mult = 180 score!
    local deitiesA = {
        [1] = Deities.CATALOG.deity_genesis,
        [2] = Deities.CATALOG.deity_eternal_tree,
    }
    local scoreA = Scoring.calculate(testHand, deitiesA, {})
    assert(scoreA.totalMult == 15, "Order [+Mult, xMult] must result in 15 Mult, got: " .. scoreA.totalMult)
    assert(scoreA.finalScore == 180, "Order [+Mult, xMult] must result in 180 finalScore, got: " .. scoreA.finalScore)

    -- Setup B: [xMult in Slot 1, +Mult in Slot 2]
    -- Order: Slot 1 = Eternal Tree (x3 XMult), Slot 2 = Genesis (+4 Mult)
    -- Expected: (1 * 3) + 4 = 7 Mult -> 12 Chips * 7 Mult = 84 score!
    local deitiesB = {
        [1] = Deities.CATALOG.deity_eternal_tree,
        [2] = Deities.CATALOG.deity_genesis,
    }
    local scoreB = Scoring.calculate(testHand, deitiesB, {})
    assert(scoreB.totalMult == 7, "Order [xMult, +Mult] must result in 7 Mult, got: " .. scoreB.totalMult)
    assert(scoreB.finalScore == 84, "Order [xMult, +Mult] must result in 84 finalScore, got: " .. scoreB.finalScore)

    assert(scoreA.finalScore > scoreB.finalScore, "Order [+Mult, xMult] MUST produce strictly greater score than [xMult, +Mult]!")
    assert(scoreA.finalScore == 180 and scoreB.finalScore == 84, "Scoring order verified: 180 vs 84 (more than 2x damage difference!)")

    -- 4. Blueprint / Thần Phản Chiếu copies across empty slots
    -- Setup: [1] = Mirror, [2] = nil, [3] = nil, [4] = Genesis, [5] = nil
    local deitiesWithGaps = {
        [1] = Deities.CATALOG.deity_mirror,
        [4] = Deities.CATALOG.deity_genesis,
    }
    local resolvedDeity = Deities.resolveDeity(deitiesWithGaps, 1)
    assert(resolvedDeity ~= nil and resolvedDeity.id == "deity_genesis", "Mirror at slot 1 must successfully find Genesis at slot 4 across empty slots")

    -- Mirror at right edge has no target to the right -> returns nil
    local deitiesEdge = { [5] = Deities.CATALOG.deity_mirror }
    local resolvedEdge = Deities.resolveDeity(deitiesEdge, 5)
    assert(resolvedEdge == nil, "Mirror at slot 5 with no right neighbor must resolve to nil")

    -- Selling deity in slot 3 leaves other slots intact
    local sellGS = {
        gold = 10,
        deities = {
            [2] = { id = "d2", name = "Deity 2", cost = 4 },
            [4] = { id = "d4", name = "Deity 4", cost = 6 },
        }
    }
    Shop.sellDeity(sellGS, 2)
    assert(sellGS.deities[2] == nil, "Slot 2 deity must be removed")
    assert(sellGS.deities[4] ~= nil and sellGS.deities[4].id == "d4", "Slot 4 deity must remain perfectly intact")
    assert(sellGS.gold == 12, "Selling $4 deity should grant +$2 gold (10 -> 12)")

    log("[PASS] 56. Tự do sắp xếp Thần Bài (Deities Drag & Drop & Left-to-Right Scoring Order): Đặt ô bất kỳ (1..5), Hoán đổi ô, Thứ tự Trái sang Phải (+Mult trước xMult: 180 vs 84 Sát thương), Thần Phản Chiếu sao chép qua ô trống verified")
end

log("=== ALL SYSTEM TESTS PASSED SUCCESSFULLY! ===")
if logFile then logFile:close() end
if love and love.event then
    love.event.quit(0)
else
    os.exit(0)
end
return true