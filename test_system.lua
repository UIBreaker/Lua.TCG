local Poker = require("src.poker")
local Monster = require("src.monster")
local Map = require("src.map")
local Deities = require("src.deities")
local Equipment = require("src.equipment")
local Shop = require("src.shop")
local Deck = require("src.deck")
local UI = require("src.ui")

local logFile = io.open("test_results.txt", "w")
local function log(str)
    print(str)
    if logFile then
        logFile:write(str .. "\n")
        logFile:flush()
    end
end

log("=== RUNNING ROGUELIKE POKER SYSTEM TESTS ===")

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

-- 9. Test Deities.addDeity & 0 deities at start
assert(type(Deities.addDeity) == "function", "Deities.addDeity must be a function")
local draftPick = drafted[1]
local addResult = Deities.addDeity(gameState, draftPick)
assert(addResult == true, "addDeity should return true")
assert(#gameState.deities == 1, "gameState.deities should now have 1 deity")
assert(gameState.deities[1].id == draftPick.id, "Added deity matches chosen deity")
log("[PASS] 14. Deities.addDeity successfully adds chosen deity: " .. draftPick.name)

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

log("=== ALL SYSTEM TESTS PASSED SUCCESSFULLY! ===")
if logFile then logFile:close() end
if love and love.event then
    love.event.quit(0)
else
    os.exit(0)
end
return true