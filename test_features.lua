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
    assert(c.suit == "hearts", "Expected card suit to be hearts, got " .. c.suit)
end
print(" Test 1 Passed: Mono-Suit Deck (52 cards all Hearts)")

-- Test 2: Monster and Boss stage logic
local m1 = Monster.create(1)
assert(m1.isBoss == false, "Round 1 should be normal monster")
assert(m1.hp == 300, "Round 1 HP should be 300")

local m3 = Monster.create(3)
assert(m3.isBoss == false, "Round 3 should be normal monster")

local m4 = Monster.create(4)
assert(m4.isBoss == true, "Round 4 should be BOSS")
assert(m4.hp == 2500, "Round 4 Boss HP should be 2500")

local m8 = Monster.create(8)
assert(m8.isBoss == true, "Round 8 should be BOSS 2")
print(" Test 2 Passed: 3 Normal Stages then 1 Boss Stage Loop")

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
local c1 = Deck.newCard(10, "hearts")
Equipment.attach(c1, Equipment.ITEMS.gem_fire)

local c2 = Deck.newCard(10, "hearts")
Equipment.attach(c2, Equipment.ITEMS.gem_blast)
Equipment.attach(c2, Equipment.ITEMS.lucky_coin)

local pairHand = Poker.evaluate({ c1, c2 })
local calc = Scoring.calculate(pairHand, {}, {})
assert(calc.totalChips == 65, "Expected 65 chips, got " .. calc.totalChips)
assert(calc.totalMult == 12, "Expected 12 mult, got " .. calc.totalMult)
assert(calc.finalScore == 780, "Expected 780 final score, got " .. calc.finalScore)
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
-- Base trips: 30 chips, 3 mult.
-- Cards: 9 + 9 + 9 = 27 chips.
-- Mirror buffs: ca gets +25, cc gets +25 = +50 chips.
-- Total chips: 30 + 27 + 50 = 107 chips.
assert(calcTrips.totalChips == 107, "Expected 107 chips with adjacent mirror, got " .. calcTrips.totalChips)
print(" Test 5 Passed: Spillover Mirror Adjacent Buff")

print("=== ALL 5 ADVANCED TESTS PASSED! ===")
love.filesystem.write("adv_test_result.txt", "ALL_PASSED")
