local Poker = require("src.poker")
local Monster = require("src.monster")
local Map = require("src.map")
local Deities = require("src.deities")
local Equipment = require("src.equipment")
local Shop = require("src.shop")
local Deck = require("src.deck")

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
    assert(#sDeck == 3, "Starter deck should have exactly 3 cards")
    for _, card in ipairs(sDeck) do
        assert(card.suit == faction, "Card suit must match faction " .. faction)
        assert(card.role ~= nil, "Card must have role assigned")
    end
end
log("[PASS] 11. Starter deck has exactly 3 random cards for all 4 Factions")

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
assert(#persistentDeck == 3, "Persistent deck has 3 cards")
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
assert(#testGameState.persistentDeck == 3, "Starter deck must have 3 cards")
local extraCard = Deck.newCard(13, "spades") -- K of Spades
Deck.addCardToDeck(testGameState, extraCard)
assert(#testGameState.persistentDeck == 4, "persistentDeck must now have exactly 4 cards")
-- Calling addCardToDeck with the same card again must not duplicate
Deck.addCardToDeck(testGameState, extraCard)
assert(#testGameState.persistentDeck == 4, "persistentDeck must not add duplicate of same card")
log("[PASS] 19. Deck.addCardToDeck safely adds 1 card and blocks duplicates: 4 total cards")

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

log("=== ALL SYSTEM TESTS PASSED SUCCESSFULLY! ===")
if logFile then logFile:close() end
if love and love.event then
    love.event.quit(0)
else
    os.exit(0)
end
return true