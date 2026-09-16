local Deities = require("src.deities")
local Equipment = require("src.equipment")
local Deck = require("src.deck")
local Shop = require("src.shop")
local Monster = require("src.monster")
local RunManager = require("src.run_manager")
local Poker = require("src.poker")

local Collection = {}

-- Definition of all Compendium Categories matching media_1789532874907.png
Collection.CATEGORIES = {
    -- Left Column
    {
        id = "jokers",
        title = "Joker",
        sub = "Thần Hộ Mệnh",
        col = "left",
        btnColor = { 0.58, 0.16, 0.14, 1 }, -- Dark Crimson / Reddish Brown
        badge = "25",
    },
    {
        id = "decks",
        title = "Bộ Bài",
        sub = "Phe Phái Khởi Đầu",
        col = "left",
        btnColor = { 0.92, 0.28, 0.22, 1 },
        badge = "4",
    },
    {
        id = "vouchers",
        title = "Phiếu",
        sub = "Bí Tịch & Đặc Quyền",
        col = "left",
        btnColor = { 0.92, 0.28, 0.22, 1 },
        badge = "9",
        alert = true,
    },
    {
        id = "consumables",
        title = "Lá Tiêu Thụ",
        sub = "Trang Bị Khảm Ngọc",
        col = "left",
        isBigOrange = true,
        btnColor = { 0.96, 0.54, 0.08, 1 }, -- Bright Balatro Orange
        badge = "8",
    },

    -- Right Column
    {
        id = "enhancements",
        title = "Lá Cường Hoá",
        sub = "Tôi Luyện Bài",
        col = "right",
        btnColor = { 0.92, 0.28, 0.22, 1 },
        badge = "6",
    },
    {
        id = "seals",
        title = "Con Dấu",
        sub = "Dấu Ấn Ma Pháp",
        col = "right",
        btnColor = { 0.92, 0.28, 0.22, 1 },
        badge = "4",
    },
    {
        id = "editions",
        title = "Ấn Bản",
        sub = "Hiệu Ứng Phủ Bài",
        col = "right",
        btnColor = { 0.92, 0.28, 0.22, 1 },
        badge = "4",
        alert = true,
    },
    {
        id = "packs",
        title = "Gói Bài",
        sub = "Gói Thẻ Cửa Hàng",
        col = "right",
        btnColor = { 0.92, 0.28, 0.22, 1 },
        badge = "5",
    },
    {
        id = "tags",
        title = "Nhãn Bỏ Qua",
        sub = "Phần Thưởng Skip Blind",
        col = "right",
        btnColor = { 0.92, 0.28, 0.22, 1 },
        badge = "8",
        alert = true,
    },
    {
        id = "blinds",
        title = "Blind",
        sub = "Quái & Dị Biến Boss",
        col = "right",
        btnColor = { 0.92, 0.28, 0.22, 1 },
        isTall = true,
        badge = "9",
        alert = true,
    },
    {
        id = "other",
        title = "Khác",
        sub = "Tổ Hợp & Luật Bài",
        col = "right",
        btnColor = { 0.92, 0.28, 0.22, 1 },
        badge = "9",
    },
}

-- Static items for categories that don't have dedicated Lua modules
local ENHANCEMENTS = {
    { id = "enh_stone", name = "Lá Đá (Stone Card)", rarity = "Thường", desc = "+50 Chips cố định. Không có Rank và không có Chất. Luôn luôn ghi điểm!", icon = "🪨", color = { 0.65, 0.65, 0.70, 1 } },
    { id = "enh_steel", name = "Lá Thép (Steel Card)", rarity = "Hiếm", desc = "Nhân x1.5 XMult khi lá bài này nằm lại trên tay (không đánh ra) lúc kết thúc tính điểm.", icon = "🛡️", color = { 0.45, 0.55, 0.65, 1 } },
    { id = "enh_gold", name = "Lá Vàng (Gold Card)", rarity = "Hiếm", desc = "Thưởng ngay +$3 Vàng vào kho khi lá bài này nằm lại trên tay lúc chiến thắng vòng đấu.", icon = "💰", color = { 0.95, 0.82, 0.22, 1 } },
    { id = "enh_wild", name = "Lá Vạn Năng (Wild Card)", rarity = "Hiếm", desc = "Có thể đại diện cho bất kỳ Chất nào (Cơ, Rô, Chuồn, Bích) để tạo nên bộ Thùng và Sảnh!", icon = "🌈", color = { 0.85, 0.35, 0.85, 1 } },
    { id = "enh_lucky", name = "Lá May Mắn (Lucky Card)", rarity = "Huyền Thoại", desc = "1/5 cơ hội kích hoạt +20 Mult, và 1/15 cơ hội trúng giải độc đắc +$20 Vàng khi ghi điểm!", icon = "🍀", color = { 0.30, 0.85, 0.45, 1 } },
    { id = "enh_glass", name = "Lá Pha Lê (Glass Card)", rarity = "Huyền Thoại", desc = "Nhân x2.0 XMult khổng lồ khi ghi điểm! Có 1/4 khả năng vỡ vụn biến mất sau khi kích hoạt.", icon = "💎", color = { 0.60, 0.85, 0.95, 1 } },
}

local SEALS = {
    { id = "seal_red", name = "Dấu Ấn Đỏ (Red Seal)", rarity = "Hiếm", desc = "Tái kích hoạt (Retrigger) toàn bộ hiệu ứng của lá bài này thêm 1 lần nữa khi tính điểm!", icon = "🔴", color = { 0.90, 0.22, 0.25, 1 } },
    { id = "seal_blue", name = "Dấu Ấn Xanh (Blue Seal)", rarity = "Hiếm", desc = "Tạo ra 1 Thẻ Thiên Thể nâng cấp tay bài cuối cùng đánh ra nếu lá này còn trên tay khi thắng.", icon = "🔵", color = { 0.20, 0.55, 0.95, 1 } },
    { id = "seal_gold", name = "Dấu Ấn Vàng (Gold Seal)", rarity = "Hiếm", desc = "Thưởng trực tiếp +$3 Vàng mỗi lần lá bài này được chọn và ghi điểm trong vòng đấu!", icon = "🟡", color = { 0.95, 0.85, 0.20, 1 } },
    { id = "seal_purple", name = "Dấu Ấn Tím (Purple Seal)", rarity = "Hiếm", desc = "Tạo ngay 1 Thẻ Phù Chú (Tarot) ngẫu nhiên khi người chơi chọn Discard (Bỏ) lá bài này!", icon = "🟣", color = { 0.65, 0.30, 0.85, 1 } },
}

local EDITIONS = {
    { id = "ed_base", name = "Ấn Bản Chuẩn (Standard)", rarity = "Cơ Bản", desc = "Lá bài gốc nguyên bản không mang lớp phủ quang học ma thuật.", icon = "🃏", color = { 0.70, 0.70, 0.70, 1 } },
    { id = "ed_foil", name = "Mạ Bạc (Foil)", rarity = "Đặc Biệt", desc = "Phủ một lớp kim loại bạc lấp lánh: Tặng thêm +50 Chips cố định mỗi khi kích hoạt!", icon = "✨", color = { 0.35, 0.75, 0.95, 1 } },
    { id = "ed_holo", name = "Quang Phổ (Holographic)", rarity = "Hiếm", desc = "Phản chiếu 7 sắc cầu vồng: Tặng thêm +10 Mult cho tổng điểm tay bài khi kích hoạt!", icon = "🌟", color = { 0.85, 0.35, 0.85, 1 } },
    { id = "ed_poly", name = "Đa Sắc (Polychrome)", rarity = "Huyền Thoại", desc = "Hào quang ngũ sắc rực rỡ: Nhân x1.5 XMult trực tiếp vào điểm số cuối cùng!", icon = "🌈", color = { 0.95, 0.80, 0.20, 1 } },
}

local PACKS = {
    { id = "pack_buffoon", name = "Gói Thần Bài (Buffoon Pack)", cost = 4, rarity = "Đặc Quyền", desc = "Mở ra 2 lá Thần Hộ Mệnh (Joker) ngẫu nhiên. Chọn 1 lá để thỉnh về trợ chiến!", icon = "🃏", color = { 0.90, 0.40, 0.20, 1 } },
    { id = "pack_standard", name = "Gói Quân Binh (Standard Pack)", cost = 4, rarity = "Tiêu Chuẩn", desc = "Mở ra 3 quân bài ma thuật kèm cường hóa hoặc ấn bản. Chọn 1 lá thêm vào bộ bài!", icon = "🎴", color = { 0.25, 0.60, 0.90, 1 } },
    { id = "pack_arcana", name = "Gói Trang Bị (Arcana Pack)", cost = 4, rarity = "Ma Pháp", desc = "Mở ra 3 Trang Bị Khảm Ngọc ngẫu nhiên. Chọn 1 bảo vật để khảm vào quân bài!", icon = "🔮", color = { 0.65, 0.35, 0.85, 1 } },
    { id = "pack_celestial", name = "Gói Thiên Thể (Celestial Pack)", cost = 4, rarity = "Thần Thánh", desc = "Mở ra các hành tinh ban phước, tăng vĩnh viễn Chips và Mult cho một thế bài cụ thể!", icon = "🪐", color = { 0.20, 0.75, 0.75, 1 } },
    { id = "pack_spectral", name = "Gói U Hồn (Spectral Pack)", cost = 6, rarity = "Cấm Kỵ", desc = "Mở ra các phép thuật biến dị cổ đại cực mạnh nhưng mang theo tác dụng phụ khó lường!", icon = "👻", color = { 0.85, 0.20, 0.40, 1 } },
}

local VOUCHERS = {
    { id = "v_discount", name = "Thẻ Thành Viên (Overstock)", rarity = "Phiếu", cost = 10, desc = "Giảm vĩnh viễn -$2 giá gieo lại (Reroll) tại mọi Cửa Hàng suốt cả hành trình!", icon = "🎟️", color = { 0.35, 0.85, 0.55, 1 } },
    { id = "v_interest", name = "Sổ Tiết Kiệm (Money Tree)", rarity = "Phiếu", cost = 10, desc = "Tăng trần mức lãi ngân khố sau mỗi trận từ +$5 lên tối đa +$10 mỗi ván!", icon = "💰", color = { 0.95, 0.80, 0.25, 1 } },
    { id = "v_hand_plus", name = "Bùa Hảo Thủ (Grabber)", rarity = "Phiếu", cost = 10, desc = "Tăng vĩnh viễn +1 Lượt Đánh bài (Max Hands) tối đa trong mọi trận chiến!", icon = "✋", color = { 0.85, 0.45, 0.95, 1 } },
    { id = "v_discard_plus", name = "Túi Đổi Vận (Wasteful)", rarity = "Phiếu", cost = 10, desc = "Tăng vĩnh viễn +1 Lượt Đổi bài (Max Discards) tối đa trong mọi trận chiến!", icon = "🔄", color = { 0.40, 0.75, 0.95, 1 } },
    { id = "v_crystal", name = "Kính Ma Thuật (Telescope)", rarity = "Phiếu", cost = 10, desc = "Gói Thiên Thể luôn chứa hành tinh nâng cấp cho tay bài bạn chơi nhiều nhất!", icon = "🔭", color = { 0.30, 0.85, 0.85, 1 } },
    { id = "v_omen", name = "Chiêm Tinh Cổ (Omen Globe)", rarity = "Phiếu", cost = 10, desc = "Gói Trang Bị có tỷ lệ xuất hiện các cổ vật Huyền Thoại và Ấn Bản quý hiếm!", icon = "🔮", color = { 0.75, 0.40, 0.90, 1 } },
    { id = "v_directors", name = "Lệnh Giám Khảo (Director's Cut)", rarity = "Phiếu", cost = 10, desc = "Cho phép Gieo Lại (Reroll) Boss Blind 1 lần mỗi Ante với giá $10!", icon = "🎬", color = { 0.95, 0.50, 0.20, 1 } },
    { id = "v_glow", name = "Quang Diệu (Glow Up)", rarity = "Phiếu", cost = 10, desc = "Tăng gấp đôi tỷ lệ xuất hiện Thần Bài mang hiệu ứng Foil, Holo, Polychrome!", icon = "✨", color = { 0.95, 0.85, 0.30, 1 } },
    { id = "v_reroll_surplus", name = "Chợ Đen (Reroll Surplus)", rarity = "Phiếu", cost = 10, desc = "Giá khởi điểm gieo lại tại Cửa Hàng giảm xuống còn $3 (bình thường $5)!", icon = "🏷️", color = { 0.40, 0.90, 0.60, 1 } },
}

function Collection.getCategories()
    return Collection.CATEGORIES
end

function Collection.getCategoryById(catId)
    for _, cat in ipairs(Collection.CATEGORIES) do
        if cat.id == catId then return cat end
    end
    return nil
end

function Collection.getItems(category)
    local items = {}

    if category == "jokers" then
        -- Harvest all deities from Deities.CATALOG
        for id, d in pairs(Deities.CATALOG) do
            table.insert(items, {
                id = d.id or id,
                name = d.name or "Thần Vô Danh",
                subtitle = (d.suit and string.upper(d.suit) or "THẦN BÀI") .. " • " .. string.upper(d.rarity or "UNCOMMON"),
                rarity = d.rarity or "uncommon",
                cost = d.cost or 5,
                desc = d.desc or "Hiệu ứng thần bài hộ mệnh",
                icon = "🃏",
                color = (d.rarity == "legendary" and { 0.95, 0.82, 0.22, 1 }) or
                        (d.rarity == "rare" and { 0.88, 0.35, 0.88, 1 }) or
                        (d.rarity == "uncommon" and { 0.35, 0.75, 0.95, 1 }) or
                        { 0.75, 0.75, 0.75, 1 },
                suit = d.suit,
            })
        end
        table.sort(items, function(a, b) return a.name < b.name end)

    elseif category == "consumables" then
        -- Harvest all equipment from Equipment.ITEMS
        for id, eq in pairs(Equipment.ITEMS) do
            table.insert(items, {
                id = eq.id or id,
                name = eq.name or "Trang Bị",
                subtitle = "NGỌC KHẢM MA PHÁP",
                rarity = "Bảo Vật",
                cost = eq.cost or 4,
                desc = eq.desc or "Ngọc ma thuật dùng khảm vào ô trống của lá bài",
                icon = eq.icon or "💎",
                color = eq.color or { 0.95, 0.54, 0.08, 1 },
            })
        end
        table.sort(items, function(a, b) return a.name < b.name end)

    elseif category == "decks" then
        -- 4 Archetype Factions using Deck.FACTION_ORDER
        for _, fid in ipairs(Deck.FACTION_ORDER or { "vharos", "valoria", "aurelia", "elaris" }) do
            local f = Deck.FACTIONS[fid]
            if f then
                table.insert(items, {
                    id = f.id or fid,
                    name = f.name or f.title,
                    subtitle = f.fullName or f.title,
                    rarity = "Phe Phái",
                    desc = (f.archetype or "") .. "\n• " .. (f.passive1 or "") .. "\n• " .. (f.passive2 or ""),
                    icon = f.symbol or "♠",
                    color = f.color or { 0.8, 0.8, 0.8, 1 },
                    badge = f.symbol,
                })
            end
        end

    elseif category == "vouchers" then
        for _, v in ipairs(VOUCHERS) do
            table.insert(items, v)
        end

    elseif category == "enhancements" then
        for _, enh in ipairs(ENHANCEMENTS) do
            table.insert(items, enh)
        end

    elseif category == "seals" then
        for _, s in ipairs(SEALS) do
            table.insert(items, s)
        end

    elseif category == "editions" then
        for _, ed in ipairs(EDITIONS) do
            table.insert(items, ed)
        end

    elseif category == "packs" then
        for _, p in ipairs(PACKS) do
            table.insert(items, p)
        end

    elseif category == "tags" then
        for _, t in ipairs(RunManager.TAGS or {}) do
            table.insert(items, {
                id = t.id,
                name = t.name,
                subtitle = "NHÃN BỎ QUA",
                rarity = "Thẻ Thưởng",
                desc = t.desc,
                icon = t.icon or "🏷️",
                color = t.color or { 0.95, 0.82, 0.22, 1 },
            })
        end

    elseif category == "blinds" then
        -- Normal, Elite, and Bosses
        table.insert(items, {
            id = "blind_small",
            name = "Small Blind (Cược Nhỏ)",
            subtitle = "VÒNG ĐẤU CƠ BẢN",
            rarity = "Tiêu Chuẩn",
            desc = "Mục tiêu điểm chuẩn theo Ante hiện tại. Có thể Bỏ Qua để nhận Thẻ Thưởng Skip Tag!",
            icon = "🔷",
            color = { 0.35, 0.65, 0.95, 1 },
        })
        table.insert(items, {
            id = "blind_big",
            name = "Big Blind (Cược Lớn)",
            subtitle = "VÒNG ĐẤU THỬ THÁCH",
            rarity = "Thử Thách",
            desc = "Mục tiêu 1.5x điểm. Thưởng nhiều Vàng hơn và có thể Bỏ Qua nhận Thẻ Thưởng quý!",
            icon = "🔶",
            color = { 0.95, 0.55, 0.20, 1 },
        })

        -- 6 Disruptive Bosses
        for id, b in pairs(Monster.DISRUPTIVE_BOSSES or {}) do
            table.insert(items, {
                id = b.id or id,
                name = b.name,
                subtitle = b.title or "BOSS DỊ BIẾN",
                rarity = "Boss",
                desc = b.desc or "Lời nguyền áp chế đặc biệt của Boss Blind. Không thể Bỏ Qua!",
                icon = "💀",
                color = b.color or { 0.95, 0.25, 0.25, 1 },
            })
        end

    elseif category == "other" then
        -- 9 Poker Hand Types
        for _, h in ipairs(Poker.HAND_TYPES_ORDERED or {}) do
            table.insert(items, {
                id = h.id,
                name = h.vnName or h.name,
                subtitle = "TAY BÀI: " .. string.upper(h.name),
                rarity = "Tổ Hợp Bài",
                desc = "Điểm cơ sở: " .. h.baseChips .. " Chips x " .. h.baseMult .. " Mult.\nĐộ hiếm nâng cấp tăng mạnh khi sở hữu Bí Tịch Thiên Thể!",
                icon = "🎴",
                color = { 0.40, 0.75, 0.95, 1 },
            })
        end
    end

    return items
end

return Collection
