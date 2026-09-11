local Capture = {}

local frame = 0
local Equipment = require("src.equipment")

local function saveImage(name)
    love.graphics.captureScreenshot(function(imgData)
        local fileData = imgData:encode("png")
        local bytes = fileData:getString()
        local f = io.open(name, "wb")
        if f then
            f:write(bytes)
            f:close()
            print("[CAPTURED] " .. name)
        else
            print("[ERROR OPENING] " .. name)
        end
    end)
end

function Capture.update(gameRef, callbacks)
    frame = frame + 1

    if frame == 2 then
        saveImage("shot_main_menu.png")

    elseif frame == 6 then
        if callbacks.setMenuMode then callbacks.setMenuMode("faction_select") end
        saveImage("shot_menu.png")

    elseif frame == 12 then
        callbacks.startNewGame("aurelia")
        if callbacks.openPauseMenu then callbacks.openPauseMenu() end
        saveImage("shot_pause_menu.png")

    elseif frame == 18 then
        if callbacks.closePauseMenu then callbacks.closePauseMenu() end
        if callbacks.openSettings then callbacks.openSettings() end
        saveImage("shot_settings.png")

    elseif frame == 24 then
        if callbacks.closeSettings then callbacks.closeSettings() end
        saveImage("shot_map.png")

    elseif frame == 34 then
        callbacks.startMonsterEncounter(1, false)
        if gameRef.hand and gameRef.hand[1] then
            Equipment.attach(gameRef.hand[1], Equipment.ITEMS.gem_fire)
            Equipment.attach(gameRef.hand[1], Equipment.ITEMS.mirror_adjacent)
        end
        saveImage("shot_combat_starter.png")

    elseif frame == 44 then
        callbacks.openInspector(gameRef.hand[1])
        saveImage("shot_card_inspector.png")

    elseif frame == 54 then
        callbacks.closeInspector()
        callbacks.openHandbook()
        saveImage("shot_handbook.png")

    elseif frame == 64 then
        callbacks.closeHandbook()
        callbacks.openShop()
        saveImage("shot_shop.png")

    elseif frame == 72 then
        callbacks.openShopTransfer()
        saveImage("shot_shop_transfer.png")

    elseif frame == 82 then
        callbacks.closeShopTransfer()
        callbacks.openRest()
        saveImage("shot_rest.png")

    elseif frame == 92 then
        callbacks.openBossDeity()
        saveImage("shot_boss_deity.png")

    elseif frame == 102 then
        -- Add 1 reward card (e.g. K of Spades) to persistent deck and open Socketing
        local Deck = require("src.deck")
        local kSpades = Deck.newCard(13, "spades")
        Deck.addCardToDeck(gameRef, kSpades)
        callbacks.openSocketing(Equipment.ITEMS.feather_free)
        saveImage("shot_socketing_fix.png")

    elseif frame == 112 then
        callbacks.openDeckViewer()
        saveImage("shot_deck_viewer_fix.png")

    elseif frame == 122 then
        callbacks.closeDeckViewer()
        callbacks.startMonsterEncounter(1, false)
        callbacks.selectCardIndex(1)
        saveImage("shot_hand_selection_fix.png")

    elseif frame == 132 then
        callbacks.playSelectedHand()

    elseif frame == 145 then
        saveImage("shot_scoring_juice.png")

    elseif frame == 165 then
        print("All screenshots captured!")
        love.event.quit(0)
    end
end

return Capture
