local Deck = require("src.deck")
local Poker = require("src.poker")
local Deities = require("src.deities")
local Scoring = require("src.scoring")
local Monster = require("src.monster")
local Equipment = require("src.equipment")

print("=== RUNNING ADVANCED FEATURES TEST ===")

-- Test 1: Mono-suit deck
local monoDeck = Deck.createMonoSuitDeck("hearts")
assert(#monoDeck == 52, "Expected 52 cards in mono-suit deck, got " .. #monoDeck)
for _, c in ipairs(monoDeck) do
    assert(c.suit == "valoria", "Hearts alias must canonicalize to valoria, got " .. c.suit)
end
print(" Test 1 Passed: Mono-Suit Deck (52 cards all Hearts)")

-- Test 2: Monster and Boss stage logic
local m1 = Monster.create(1)
assert(m1.isBoss == false, "Round 1 should be normal monster")
assert(m1.hp == 76, "Encounter 1 HP should be 76")

local m3 = Monster.create(3)
assert(m3.isBoss == false, "Round 3 should be normal monster")

local m4 = Monster.create(4, true, false, 4)
assert(m4.isBoss == true, "Round 4 should be BOSS")
assert(m4.hp == 514, "Encounter 4 Boss HP should be 514")

local m8 = Monster.create(8, true, false, 8)
assert(m8.isBoss == true, "Round 8 should be BOSS 2")
assert(m8.hp > m4.hp, "Later boss encounters must scale above earlier bosses")
print(" Test 2 Passed: Explicit normal/boss encounters and HP scaling")

-- Test 3: Card Equipment attachment (max 5 slots)
local card = Deck.newCard(14, "hearts")
assert(#card.equipments == 0)
for i = 1, 5 do
    local ok, msg = Equipment.attach(card, Equipment.ITEMS.gem_fire)
    assert(ok == true, "Attachment should succeed for slot " .. i)
end
assert(#card.equipments == 5)
local failOk, failMsg = Equipment.attach(card, Equipment.ITEMS.gem_blast)
assert(failOk == false, "6th equipment should be rejected")
print(" Test 3 Passed: 5 Equipment Slots per Card Limit")

-- Test 4: Scoring with Equipment
-- Card 1: 10 of hearts with Fire Gem (+35 Chips)
-- Card 2: 10 of hearts with Blast Gem (+10 Mult) and Lucky Coin (+$3 gold)
-- Base Pair = 10 chips, 2 mult
-- Card chips = 10 + 10 = 20
-- Equipment chips = +35 (Fire Gem)
-- Total Chips = 10 + 20 + 35 = 65
-- Equipment mult = +10 (Blast Gem)
-- Total Mult = 2 + 10 = 12
-- Final Score = 65 * 12 = 780
local baseC1 = Deck.newCard(10, "hearts")
local baseC2 = Deck.newCard(10, "hearts")
local basePair = Poker.evaluate({ baseC1, baseC2 })
local baseCalc = Scoring.calculate(basePair, {}, {})

local c1 = Deck.newCard(10, "hearts")
Equipment.attach(c1, Equipment.ITEMS.gem_fire)

local c2 = Deck.newCard(10, "hearts")
Equipment.attach(c2, Equipment.ITEMS.gem_blast)
Equipment.attach(c2, Equipment.ITEMS.lucky_coin)

local pairHand = Poker.evaluate({ c1, c2 })
local calc = Scoring.calculate(pairHand, {}, {})
assert(calc.totalChips == baseCalc.totalChips + 35, "Fire Gem must add exactly 35 chips")
assert(calc.totalMult == baseCalc.totalMult + 10, "Blast Gem must add exactly 10 mult")
assert(calc.finalScore > baseCalc.finalScore, "Equipment must increase final score")
assert(calc.bonusGoldAwarded == 3, "Expected 3 gold awarded, got " .. calc.bonusGoldAwarded)
print(" Test 4 Passed: Equipment Chips, Mult, and Gold Integration")

-- Test 5: Adjacent Mirror equipment
-- cA (9), cB (9 with mirror), cC (9)
-- cB should buff cA (+25 chips) and cC (+25 chips)
local ca = Deck.newCard(9, "hearts")
local cb = Deck.newCard(9, "hearts")
Equipment.attach(cb, Equipment.ITEMS.mirror_adjacent)
local cc = Deck.newCard(9, "hearts")

local trips = Poker.evaluate({ ca, cb, cc })
local calcTrips = Scoring.calculate(trips, {}, {})
local baseTrips = Poker.evaluate({ Deck.newCard(9, "hearts"), Deck.newCard(9, "hearts"), Deck.newCard(9, "hearts") })
local baseTripsCalc = Scoring.calculate(baseTrips, {}, {})
assert(calcTrips.totalChips == baseTripsCalc.totalChips + 50, "Adjacent mirror must add exactly 50 chips")
print(" Test 5 Passed: Spillover Mirror Adjacent Buff")

print("=== ALL 5 ADVANCED TESTS PASSED! ===")
love.filesystem.write("adv_test_result.txt", "ALL_PASSED")
if love and love.audio then love.audio.stop() end
if love and love.event then love.event.quit(0) end
