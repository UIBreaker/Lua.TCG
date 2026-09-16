# 🃏 LUA.TCG - POKER ROGUELIKE DECKBUILDER

> Một tựa game thẻ bài chiến thuật Poker Roguelike phong cách Deck-building cổ điển, kết hợp yếu tố nhập vai diệt quái, phân chia 4 Đại Phe Phái (Factions), hệ thống Thứ Bậc Quân Chủng Thẻ Bài (Card Roles) và khảm ngọc trang bị độc đáo. Game được viết hoàn toàn bằng **Lua** và vận hành mượt mà trên nền tảng **LÖVE 2D (Love2D v11.5)**.

[![GitHub Repository](https://img.shields.io/badge/GitHub-UIBreaker%2FLua.TCG-blue?logo=github)](https://github.com/UIBreaker/Lua.TCG.git)
[![Engine](https://img.shields.io/badge/Engine-LÖVE%2011.5-pink?logo=lua)](https://love2d.org/)
[![Tests](https://img.shields.io/badge/Tests-46%2F46%20Passing-brightgreen)](test_system.lua)

---

## 📑 MỤC LỤC
1. [Khởi Chạy Nhanh](#-khởi-chạy-nhanh)
2. [4 Đại Phe Phái Khởi Đầu (Factions)](#-1-4-đại-phe-phái-khởi-đầu-factions)
3. [Hệ Thống Thứ Bậc Quân Chủng (Card Hierarchy & Roles)](#-2-hệ-thống-thứ-bậc-quân-chủng-card-hierarchy--roles)
4. [Bản Đồ Hành Trình 20 Tầng (Act 1 Map)](#-3-bản-đồ-hành-trình-20-tầng)
5. [Cơ Chế Chiến Đấu & Công Thức Máu Quái Vật (10 HP +50%)](#-4-cơ-chế-chiến-đấu--công-thức-máu-quái-vật)
6. [Hệ Thống Mở Khóa Thế Đánh & Sổ Tay Bí Tịch](#-5-hệ-thống-mở-khóa-thế-đánh--sổ-tay-bí-tịch)
7. [Hệ Thống Khảm Trang Bị Vào Lá Bài (Socketing)](#-6-hệ-thống-khảm-trang-bị-vào-lá-bài-socketing)
8. [Cửa Hàng Lữ Khách & Hoán Đổi Trang Bị](#-7-cửa-hàng-lữ-khách--hoán-đổi-trang-bị)
9. [Hệ Thống Thần Bài Ban Ơn (Deities)](#-8-hệ-thống-thần-bài-ban-ơn-deities)
10. [Bảng Toàn Bộ Bộ Bài (Deck Viewer [Tab])](#-9-bảng-toàn-bộ-bộ-bài-deck-viewer-tab)
11. [Bảng Phím Tắt Toàn Tập](#-10-bảng-phím-tắt-toàn-tập)
12. [Cấu Trúc Thư Mục & Mã Nguồn](#-11-cấu-trúc-thư-mục--mã-nguồn)
13. [Kiểm Thử Tự Động (Automated Testing)](#-12-kiểm-thử-tự-động)

---

## 🚀 Khởi Chạy Nhanh

### 1. Chạy trên Windows
- **Cách 1 (Nhanh nhất)**: Nhấp đúp chuột vào file 
un.bat trong thư mục gốc.
- **Cách 2 (Dòng lệnh PowerShell / CMD)**:
  `powershell
  ..\love-11.5-win64\love.exe .
  `
- **Chế độ Fullscreen tràn viền**: Nhấn phím **F11** bất kỳ lúc nào để chuyển đổi chế độ Toàn Màn Hình tràn viền. Game sử dụng Canvas ảo độ phân giải gốc 1280x720, tự động co giãn sắc nét và căn giữa mượt mà trên mọi kích thước màn hình.

---

## 🏛️ 1. 4 Đại Phe Phái Khởi Đầu (Factions)

Tại màn hình khởi đầu, người chơi không còn chọn các chất bài thông thường mà sẽ tiến hành gia nhập **1 trong 4 Đại Phe Phái**, mỗi phe sở hữu đặc quyền chiến thuật và các hiệu ứng nội tại độc nhất:

| Phe Phái | Biểu Tượng | Sắc Thái | Kỹ Năng Nội Tại & Đặc Quyền |
| :--- | :---: | :---: | :--- |
| **Aurelia**<br>*(Phe Ánh Sáng)* | ☀️ | Vàng Kim Hoàng Gia | • **Hào Quang Thánh Thiện**: Nhân x1.15 XMult tổng sát thương mỗi khi tay bài đánh ra có chứa ít nhất 1 lá Aurelia.<br>• **Kỷ Luật Thần Thánh**: Các quân vương gia (J, Q, K) sở hữu điểm số uy dũng cố định, miễn nhiễm các hiệu ứng debuff từ quái vật. |
| **Elaris**<br>*(Phe Thiên Nhiên)* | 🌲 | Xanh Lục Bảo | • **Sức Sống Rừng Già**: Cầm tối đa **9 lá bài trên tay** (thay vì 8 lá). Khi Đổi bài (Discard) các lá Chiến Binh (2–10), chúng lập tức được tái chế trở lại đáy bộ bài rút thay vì vào cọc bài bỏ.<br>• **Lộc Biếc Đâm Chồi**: Hạ gục quái vật chỉ bằng <= 50% số lượt đánh tối đa (dưới 2 lượt) sẽ giúp 1 lá bài ngẫu nhiên được nâng cấp vĩnh viễn +1 Rank cơ sở. |
| **Vharos**<br>*(Phe Hắc Ám)* | 🔥 | Đỏ Thẫm Ma Quái | • **Hơi Thở Ma Quỷ**: Tặng ngay +40 Chips trực tiếp cho mỗi lá bài Vharos được đánh ra ghi điểm.<br>• **Huyết Tế Bóng Đêm**: Khi Đổi bài (Discard) các lá bài Chiến Binh (2–10), lá bài lập tức biến thành lễ vật, gây **Sát thương Chuẩn trực tiếp bằng đúng Rank lá bài** thẳng vào máu quái vật mà không cần đánh bài. |
| **Valoria**<br>*(Phe Nhân Loại)* | ⚔️ | Lam Thép Kiên Cường | • **Chiến Thuật Hành Quân**: Khởi đầu mọi trận chiến với **4 lượt Đổi Bài miễn phí** (thay vì 3 lượt), tối ưu khả năng nặn các thế bài cấp cao.<br>• **Hậu Cần Quân Khí**: Nhận thêm +25% Vàng thưởng sau mỗi lần tiêu diệt quái vật. |

- **Bộ Bài Khởi Đầu Thuần Khiết (3 Lá Ngẫu Nhiên)**:
  - Bạn khởi đầu hành trình chỉ với **chính xác 3 lá bài ngẫu nhiên** thuộc phe phái đã lựa chọn (ví dụ: K☀️, 7☀️, 3☀️).
  - Toàn bộ các lá bài khác thuộc các phe khác sẽ thu thập dần thông qua chiến lợi phẩm, Rương báu hoặc Cửa hàng.
- **Không có Thần Bài hỗ trợ ban đầu**:
  - Khởi đầu với 0 vị Thần. Các Thần Bài chỉ xuất hiện ban ơn sau khi bạn đánh bại Boss Tầng 20.
- **Giới hạn thế đánh ban đầu**:
  - Chỉ được phép đánh **1 lá đơn lẻ (ĐƠN THỦ - High Card)**. Các thế bài phối hợp cấp cao cần thu thập Sách Bí Tịch để khai mở.

---

## 🎖️ 2. Hệ Thống Thứ Bậc Quân Chủng (Card Hierarchy & Roles)

Các lá bài không chỉ đơn thuần là con số mà đại diện cho các cấp bậc quân chủng trong một đạo quân:

### 1. Hàng Ngũ Chiến Binh (Soldiers / Footmen — Lá 2 đến Lá 10)
- **Ý nghĩa**: Là lực lượng nòng cốt đông đảo để xếp các thế bài cơ bản như Trường Long (Sảnh), Đồng Khí (Thùng), Song Đao (Đôi),...
- **Chỉ số**: Điểm số Chips tăng dần từ 2 đến 10 theo Rank.
- **Tương tác Phe**: Được dùng làm vật phẩm Huyết Tế gây sát thương trực tiếp của phe Vharos, hoặc Tái Chế vô tận của phe Elaris.

### 2. Hiệp Sĩ / Cận Vệ (Knight / Vanguard — Quân J)
- **Ý nghĩa**: Đóng vai trò tướng lĩnh chỉ huy, mang lại hiệu ứng khuếch đại sức mạnh khi đứng cạnh quân sĩ.
- **Nội tại**: Tặng ngay +15 Chips & +2 Mult cho **mỗi lá bài Chiến Binh (2–10)** đi cùng trong tay bài xuất trận.

### 3. Hoàng Hậu / Phù Sư (Queen / Matriarch — Quân Q)
- **Ý nghĩa**: Bậc thầy ma thuật và điều phối bảo vật trang bị.
- **Nội tại**: Cung cấp trực tiếp x1.1 XMult tổng sát thương, đồng thời nhận thêm +15 Chips & +2 Mult cho **mỗi món trang bị đã khảm** trên người nàng.

### 4. Quốc Vương / Lãnh Chúa (King / Warlord — Quân K)
- **Ý nghĩa**: Sức mạnh vương giả áp đảo, là trụ cột gánh vác sát thương cho toàn bộ bàn cờ.
- **Nội tại**: Cố định tăng thêm +25 Chips & +5 Mult độc lập ngay khi ghi điểm.

### 5. Át Chủ Bài / Thần Khí (Ace / Relic — Quân A)
- **Ý nghĩa**: Thần khí tối thượng mang sức mạnh biến hóa linh hoạt.
- **Nội tại**: Tặng +15 Chips cộng hưởng. Có thể linh hoạt tính làm đầu thấp (1) hoặc đầu cao (14) khi kết hợp xếp các thế bài Sảnh (Straight).

> *(Ghi chú: Cơ chế hao mòn suy giảm -1 Rank khi đánh bài và vỡ thẻ A cũ đã được loại bỏ hoàn toàn. Thẻ bài của bạn giờ đây giữ vững cấp bậc bền bỉ suốt toàn bộ trận đấu).*

---

## 🗺️ 3. Bản Đồ Hành Trình 20 Tầng

Hành trình Vùng Đất 1 (Act 1) gồm **20 tầng thử thách** liên tiếp:

| Biểu tượng | Loại Địa Điểm | Ý Nghĩa & Phần Thưởng |
| :---: | :--- | :--- |
| ⚔️ | **Màn Thường (Monster)** | Gặp quái vật hoang dã. Chiến thắng nhận Vàng thưởng và mở đường đi tiếp. |
| 👹 | **Màn Tinh Anh (Elite)** | Quái vật đột biến hung bạo (1.5x HP). Đánh bại sẽ được mở Rương Cổ Vật nhận bài hiếm hoặc trang bị. |
| 🛍️ | **Cửa Hàng (Shop)** | Mua Sách Bí Tịch mở thế bài, mua Trang bị, Phù chú tiếp lực và hoán đổi trang bị giữa các lá bài. |
| 🏕️ | **Trạm Nghỉ (Rest Site)** | Lựa chọn giữa: **Dưỡng Sức** (+1 Lượt Đánh & +1 Lượt Đổi tối đa) hoặc **Tôi Luyện Lò Rèn** (+1 Rank vĩnh viễn cho 1 lá bài). |
| 🎁 | **Rương Báu (Treasure)** | Nhận miễn phí 1 trong 3 phần quà: Thẻ bài tiếp viện chỉ số cao hoặc Cổ vật trang bị. |
| ❓ | **Sự Kiện (Event)** | Gặp các nhân vật thần bí (Tiên Tri Thần Bài, Đền Cổ Bị Lãng Quên,...) mang lại cơ duyên bất ngờ. |
| 👑 | **Trùm Cuối (Boss)** | Tầng 20: Đối đầu Tối Thượng Ma Thần (2.5x HP). Chiến thắng sẽ triệu hồi 2 Vị Thần để bạn chọn 1. |

- **Cuộn bản đồ**: Sử dụng con lăn chuột (Mouse Wheel) để cuộn mượt mà xem trước lộ trình từ Tầng 1 đến Tầng 20.

---

## ⚔️ 4. Cơ Chế Chiến Đấu & Công Thức Máu Quái Vật

- **Công Thức Máu Quái Vật Tăng Tiến Vô Hạn (10 HP +50%/Màn)**:
  - Để phù hợp hoàn hảo với bộ bài khởi đầu 3 lá nhỏ gọn, Quái vật đầu tiên (Màn 1) có đúng **10 HP**.
  - Mỗi khi bước vào một trận chạm trán quái vật mới ($), lượng HP của quái sẽ tự động tăng thêm **50% không giới hạn**:
    HP_n = \text{round}\left( 10 \times 1.5^{n-1} \right)
  - *Bảng tiến trình HP thực tế:*
    - **Màn 1**: 10 HP
    - **Màn 2**: 15 HP
    - **Màn 3**: 23 HP
    - **Màn 4**: 34 HP
    - **Màn 5**: 51 HP
    - **Màn 6**: 76 HP
    - **Màn 10**: 384 HP
    - **Màn 15**: 2,919 HP
    - Quái **Tinh Anh (Elite)**: 1.5x HP của màn đó.
    - Quái **Trùm Cuối (Boss)**: 2.5x HP của màn đó.
- **Tài Nguyên Trong Trận Đấu**:
  - **Lượt Đánh (Hands)**: Mặc định 4 lượt. Hết lượt đánh mà quái chưa chết thì thua trận (Game Over).
  - **Lượt Đổi Bài (Discards)**: Mặc định 3 lượt (Phe Valoria được 4 lượt).
- **Công Thức Tính Sát Thương Thực**:
  \text{Sát Thương} = \left( \sum \text{Chips}_{\text{Cơ bản}} + \sum \text{Chips}_{\text{Role}} + \sum \text{Chips}_{\text{Trang bị}} + \sum \text{Chips}_{\text{Thần}} \right) \times \left( \text{Mult}_{\text{Cơ bản}} + \text{Mult}_{\text{Buff}} \right) \times \prod \text{XMult}

---

## 📖 5. Hệ Thống Mở Khóa Thế Đánh & Sổ Tay Bí Tịch

Mới vào game, người chơi **chỉ đánh được thế bài 1 lá (ĐƠN THỦ)**. Để tung ra các tuyệt kỹ nhiều lá, bạn phải thu thập các **Sách Bí Tịch**:

| STT | Thế Bài Poker | Tên Tiếng Việt | Số Lá | Chỉ Số Cơ Bản | Sách Bí Tịch Tương Ứng |
| :---: | :--- | :--- | :---: | :---: | :--- |
| 1 | **High Card** | ĐƠN THỦ | 1 | 5 Chips x 1 Mult | *Mở khóa sẵn từ đầu game* |
| 2 | **Pair** | SONG ĐAO (Đôi) | 2 | 10 Chips x 2 Mult | Bí Tịch: Song Đao Quyết () |
| 3 | **Two Pair** | SONG ĐÔI (Hai Đôi) | 4 | 20 Chips x 2 Mult | Bí Tịch: Song Tinh Hợp Bích () |
| 4 | **Three of a Kind** | TAM HOA (Sám Cô) | 3 | 30 Chips x 3 Mult | Bí Tịch: Tam Hoa Tụ Đỉnh () |
| 5 | **Straight** | TRƯỜNG LONG (Sảnh) | 5 | 30 Chips x 4 Mult | Bí Tịch: Trường Long Xuất Hải () |
| 6 | **Flush** | ĐỒNG KHÍ (Thùng) | 5 | 35 Chips x 4 Mult | Bí Tịch: Đồng Khí Quy Tâm () |
| 7 | **Full House** | HỖN NGUYÊN (Cù Lũ) | 5 | 40 Chips x 4 Mult | Bí Tịch: Hỗn Nguyên Nhất Thể () |
| 8 | **Four of a Kind** | TỨ TƯỢNG (Tứ Quý) | 4 | 60 Chips x 7 Mult | Bí Tịch: Tứ Tượng Trận Đồ () |
| 9 | **Straight Flush** | VẠN KIẾM QUY TÔNG | 5 | 100 Chips x 8 Mult | Bí Tịch: Vạn Kiếm Quy Tông () |

- **Hệ Thống Hạ Cấp Thông Minh**: Nếu bạn đánh ra 5 lá bài thỏa mãn Thùng Phá Sảnh nhưng chưa mua bí tịch này, hệ thống sẽ tự động hạ cấp xuống thế bài hợp lệ cao nhất bạn đã sở hữu (ví dụ: Sảnh hoặc Thùng), không làm mất lượt của người chơi.
- **Sổ Tay Bí Tịch (SỔ TAY [H])**: Nhấn phím **H** hoặc click nút SỔ TAY [H] để tra cứu nhanh danh sách các thế bài và tiến độ mở khóa.

---

## 💎 6. Hệ Thống Khảm Trang Bị Vào Lá Bài (Socketing)

Mỗi lá bài sở hữu **tối đa 5 ô khảm trang bị (Sockets)**. Các bảo vật mang lại hiệu ứng độc đáo khi lá bài được xuất chiêu:

1. 💎 **Đá Lửa**: +35 Chips trực tiếp cho lá bài này khi tính điểm.
2. 🔥 **Đá Bùng Nổ**: +10 Mult cho toàn bộ tay bài khi lá này ghi điểm.
3. 🪞 **Gương Lan Tỏa**: Buff +25 Chips cho 2 lá bài nằm kế bên khi đánh ra.
4. 🌪️ **Mắt Bão**: +3 Mult cho tất cả các lá bài CÙNG PHE trong tay bài.
5. 💰 **Đồng Tiền May Mắn**: Thưởng ngay + Vàng khi lá bài ghi điểm.
6. 🪶 **Lông Vũ Tự Do**: Khi Đổi bài (Discard) lá này, KHÔNG bị trừ lượt đổi bài.
7. 🩸 **Nhẫn Huyết Thần**: Khi lá này ghi điểm, gây thêm 15% sát thương chuẩn trừ thẳng vào máu quái.
8. 👑 **Ngọc Bội Thánh Tích**: Nhân trực tiếp x1.3 XMult vào tổng sát thương.

> 💡 **Mẹo**: Nhấp **Chuột Phải** vào bất kỳ lá bài nào trên tay hoặc trong kho để mở bảng **Soi Chi Tiết Quân Chủng & Trang Bị** (phóng to hình ảnh thẻ bài, cấp bậc quân vụ, chỉ số và danh sách 5 ô trang bị).

---

## 🏪 7. Cửa Hàng Lữ Khách & Hoán Đổi Trang Bị

- **Mua Sắm**:
  - Mua Sách Bí Tịch để mở khóa thế đánh mới.
  - Mua Trang Bị Cổ Vật và khảm trực tiếp vào 1 lá bài trong kho bài.
  - Mua Phù Chú Tiếp Lực (+1 Lượt Đánh & +1 Lượt Đổi bài tức thì).
  - Mua Lá Bài Tiếp Viện (bổ sung quân lực thuộc các phe khác).
  - Làm mới hàng bán (Reroll) với giá .
- **Hoán Đổi Trang Bị (Shop Transfer)**:
  - Cho phép tháo lắp tự do trang bị giữa các lá bài ngay trong Cửa Hàng:
    1. Chọn lá bài nguồn đang có trang bị.
    2. Chọn ô trang bị muốn tháo.
    3. Chọn lá bài đích để chuyển sang (tối đa 5 ô/lá).

---

## 👑 8. Hệ Thống Thần Bài Ban Ơn (Deities — Jokers Cổ Xưa)

Người chơi có thể thờ phụng tối đa **5 vị Thần Bài cùng lúc** (hiển thị tại thanh trên cùng màn hình). Hỗ trợ **kéo thả (Drag & Drop)** để sắp xếp lại thứ tự kích hoạt nội tại.

### 🌟 10 Thần Bài Tiêu Biểu (Chuyển Thể Từ Balatro Jokers)
1. **Thần Khởi Nguyên** *(Joker)*: +4 Mult vô điều kiện cho mọi tay bài.
2. **Tứ Đại Thần Tộc** *(Greedy/Lusty/Wrathful/Gluttonous)*:
   - **Thần Quang Huy (Aurelia ☀️)**: +4 Mult cho mỗi lá Aurelia ghi điểm.
   - **Thần Trường Sinh (Elaris 🌲)**: +4 Mult cho mỗi lá Elaris ghi điểm.
   - **Thần Huyết Lửa (Vharos 🔥)**: +4 Mult cho mỗi lá Vharos ghi điểm.
   - **Thần Thiết Huyết (Valoria ⚔️)**: +4 Mult cho mỗi lá Valoria ghi điểm.
3. **Thần Trận Pháp** *(Sly / Wily)*: +50 Chips nếu tay bài là Song Đao hoặc Tam Hoa.
4. **Thần Tinh Binh** *(Half Joker)*: +20 Mult nếu tay bài đánh ra có <= 3 lá bài (cực mạnh với bài khởi đầu 3 lá!).
5. **Thần Chiến Kỷ** *(Banner)*: +30 Chips cho mỗi lượt Đổi Bài (Discard) còn lại (synergy tuyệt vời với Valoria).
6. **Thần Bách Hoa** *(Popcorn)*: Ban đầu +20 Mult, suy giảm -4 Mult sau mỗi trận cho đến khi tan biến.
7. **Thần Kim Tài** *(Golden Joker)*: Nhận +$4 Vàng khi chiến thắng mỗi trận để tối ưu Tiền Lãi (Interest).
8. **Thần Quả Thần Bí $\rightarrow$ Thần Thụ Bất Diệt** *(Gros Michel $\rightarrow$ Cavendish)*:
   - *Thần Quả Thần Bí*: +15 Mult, 1/6 tỉ lệ thăng thiên sau mỗi trận.
   - Khi thăng thiên sẽ mở khóa *Thần Thụ Bất Diệt* trong Shop với **x3.0 XMult vĩnh viễn**!
9. **Thần Điệp Kích** *(Card Sharp)*: Nhân x3.0 XMult nếu thế bài này đã được chơi trong cùng trận đấu.
10. **Thần Phản Chiếu** *(Blueprint)*: Sao chép toàn bộ kỹ năng và nội tại của Thần Bài đứng ngay bên phải nó.

- Các vị Thần xuất hiện trong Cửa Hàng, Gói Thần Ơn (Deity Packs) hoặc sau khi đánh bại Boss Tầng 20.
- Có thể bán lại Thần trong Shop để thu hồi 50% vàng khi muốn thay đổi chiến thuật.

---

## 🗃️ 9. Bảng Toàn Bộ Bộ Bài (Deck Viewer [Tab])

Bấm phím **Tab** bất cứ lúc nào (trong trận chiến hoặc ngoài bản đồ) để mở Bảng Tổng Quan:
- Xem tổng số lá bài hiện có trong bộ bài.
- Thống kê tỷ lệ các phe phái (☀️ Aurelia, 🌲 Elaris, 🔥 Vharos, ⚔️ Valoria).
- Bộ lọc nhanh theo từng phe hoặc chỉ xem các lá đã khảm trang bị.
- Danh mục chi tiết các bí tịch và trạng thái đã mở khóa bên cột phải.

---

## ⌨️ 10. Bảng Phím Tắt Toàn Tập

| Phím Tắt | Chức Năng |
| :---: | :--- |
| **F11** | Bật / Tắt chế độ Toàn màn hình tràn viền (Fullscreen borderless). |
| **H** | Mở / Đóng nhanh **Sổ Tay Các Thế Bài Poker** (Handbook). |
| **Tab** | Mở / Đóng **Toàn Bộ Bộ Bài & Bí Tịch** (Deck Viewer). |
| **Chuột Phải** | Nhấp vào lá bài để mở bảng **Soi Chi Tiết Quân Chủng & Trang Bị**. |
| **Space** hoặc **Enter** | Tấn Công (Đánh tay bài đã chọn) / Tua nhanh hoạt ảnh tính điểm. |
| **D** | Đổi Bài (Discard các lá bài đã chọn). |
| **R** | Sắp xếp các lá bài trên tay theo Rank (Số: K -> A). |
| **S** | Sắp xếp các lá bài trên tay theo Phe Phái (Aurelia -> Elaris -> Vharos -> Valoria). |
| **Phím 1 .. 8** | Bật/tắt chọn nhanh lá bài tương ứng từ 1 đến 8 trên tay. |
| **Cuộn Chuột** | Cuộn camera di chuyển trên Bản Đồ 20 tầng. |
| **Esc** | Đóng cửa sổ modal / Bảng thông tin đang mở. |

---

## 📂 11. Cấu Trúc Thư Mục & Mã Nguồn

`	ext
poker-roguelike/
├── conf.lua               # Cấu hình cửa sổ LÖVE 2D (1280x720, VSync, Canvas)
├── main.lua               # Vòng lặp chính, quản lý Game State, Renderer và Input
├── run.bat                # Kịch bản khởi chạy game nhanh 1-click
├── test_system.lua        # Bộ kiểm thử tự động toàn diện 24 bài test
├── fonts/                 # Bộ phông chữ hỗ trợ tiếng Việt Unicode hoàn chỉnh
└── src/
    ├── deck.lua           # Xử lý 4 Phe phái, Quân chủng (Roles), tạo bài, xáo bài
    ├── deities.lua        # Hệ thống Thần bài, nội tại buff, draft sau khi diệt Boss
    ├── equipment.lua      # 8 loại trang bị, cơ chế khảm ngọc 5 ô, tính toán hiệu ứng
    ├── events.lua         # Hệ thống sự kiện ngẫu nhiên trên bản đồ
    ├── map.lua            # Thuật toán sinh bản đồ 20 tầng phân nhánh và cuộn camera
    ├── monster.lua        # Chỉ số quái (10 HP +50%), quái tinh anh và trùm cuối (HP & Debuff)
    ├── poker.lua          # Thuật toán đánh giá 9 thế bài poker & phân cấp thông minh
    ├── scoring.lua        # Bộ tính điểm theo bước (Chips x Mult x XMult), Roles & Factions
    ├── shop.lua           # Cửa hàng lữ khách, sách bí tịch, mua bán thần bài & chuyển đồ
    ├── sound.lua          # Bộ phát âm thanh giao diện và hiệu ứng chiến đấu
    └── ui.lua             # Thư viện vẽ UI, thẻ bài, huy hiệu vector 4 phe phái và bảng màu
`

---

## 🧪 12. Kiểm Thử Tự Động

Game tích hợp bộ kiểm thử tự động 24 bài test độc lập để đảm bảo độ ổn định tuyệt đối:

`	ext
=== RUNNING ROGUELIKE POKER SYSTEM TESTS ===
[PASS] 1. Encounter 1 Monster HP is 10 HP: Yêu Tinh Rừng Xanh (10 HP)
[PASS] 2. Monster HP scaling (+50% each encounter) verified: 10 -> 15 -> 23 -> 34 -> 51 HP
[PASS] 2b. Boss created with scaled HP: CHÚA QUỶ GAI GÓC (127 HP)
[PASS] 3. Starter 1-card evaluation is High Card: ĐƠN THỦ
[PASS] 4. Locked hand attempt detected and gracefully downgraded to High Card
[PASS] 5. Unlocking Song Đao allows Pair evaluation: SONG ĐAO
[PASS] 6. Act 1 Map generated with 20 floors, starter nodes available, boss on Floor 20
[PASS] 7. Map node completion unlocks connecting nodes properly
[PASS] 8. Boss Deity draft offers 2 distinct deities: Tối Thượng Thần and Thần Bùng Nổ
[PASS] 9. Shop sells Skill Books and successfully unlocks hand: pair
[PASS] 10. Selling deity refunds gold properly
[PASS] 11. Starter deck has exactly 3 random cards for all 4 Factions
[PASS] 12. Card Hierarchy verified: Chiến Binh (2-10), Hiệp Sĩ (J), Hoàng Hậu (Q), Quốc Vương (K), Thần Khí (A)
[PASS] 13. Equipment transfer between cards verified successfully
[PASS] 14. Deities.addDeity successfully adds chosen deity: Tối Thượng Thần
[PASS] 15. Encounter deck restoration verified: cards restore to initial rank in new encounter
[PASS] 16. Card addition adds strictly to deck and not hand (prevents duplicate selection bug)
[PASS] 17. Unlocked Straight correctly plays as Straight despite sharing same suit: TRƯỜNG LONG
[PASS] 18. Handbook contains all 9 poker hands ordered by rank for Compendium view
[PASS] 19. Deck.addCardToDeck safely adds 1 card and blocks duplicates: 4 total cards
[PASS] 20. Deck.cloneCard preserves exact card id for 1:1 combat tracking
[PASS] 21. Equipment attaches to persistent deck card and clones correctly into combat
[PASS] 22. Hand card selection isolates strictly to the chosen card (no 2-card selection bug)
[PASS] 23. Aurelia Hào Quang Thánh Thiện grants x1.15 XMult in scoring
[PASS] 23b. Vharos Hơi Thở Ma Quỷ grants +40 Chips in scoring
[PASS] 23c. Knight (J) synergizes with Soldier (2-10) to grant bonus Chips and Mult
[PASS] 24. Shop equipment purchase and socketing attaches properly without being erased
[PASS] 25. Deck exhaustion defeat rule verified: played cards stay in discard pile and empty deck+hand causes Defeat
[PASS] 26. UI.drawCard renders faceted gemstone sockets and gilded frame without error
[PASS] 27. Faction Discard Buffs rebalanced cleanly: Aurelia (+6/12c, +1m), Elaris (Heal), Vharos (3/6 True Dmg), Valoria (+5/8c, +$1)
[PASS] 28. Player HP & Monster Counter-Attack verified: monster counter-attacks for 12 HP
[PASS] 29. Tiền Lãi (Interest) verified: +$1 per $5 stored, capped at +$5 per combat
[PASS] 30. Skip Blind & Tag Rewards verified: node completed with tag reward: Túi Vàng Cực Lớn
[PASS] 31. 6 Disruptive Boss Abilities verified: The Needle, The Water, The Pillar, The Hook, The Fish, The Arm
[PASS] 32. UI.formatNumber verified: 15 -> 15, 1250 -> 1,250, 1234567 -> 1,234,567, 1.234e12 -> 1.234e12
[PASS] 33. Hand Drag Reordering verified: cards swap indices cleanly without data loss
[PASS] 34. Text Sanitization (variation selector stripping) & Audio Volume Clamping verified
[PASS] 35. Balatro Shop Structure (Upper/Voucher/Packs), Incremental Reroll ($5 -> $6 -> $7 -> reset $5), & Pack Opening verified
[PASS] 36. Graphics Overhaul (CRT & Psychedelic Background Shaders, 3D Card Tilt, Deity Reordering) verified
[PASS] 37. Thần Khởi Nguyên verified: +4 Mult unconditional
[PASS] 38. Tứ Đại Thần Tộc verified: +4 Mult per faction card scored
[PASS] 39. Thần Trận Pháp verified: +50 Chips for tactical formations (Pair / Trips)
[PASS] 40. Thần Tinh Binh verified: +20 Mult strictly for hands <= 3 cards
[PASS] 41. Thần Chiến Kỷ verified: +30 Chips per remaining Discard (4 discards = +120 Chips)
[PASS] 42. Thần Bách Hoa verified: decaying Mult (+20 -> +16 -> ... -> extinct)
[PASS] 43. Thần Kim Tài verified: +$4 Gold on round win
[PASS] 44. Thần Quả Thần Bí & Thần Thụ Bất Diệt verified: extinction triggers Cavendish unlock & x3.0 XMult
[PASS] 45. Thần Điệp Kích verified: x3.0 XMult on repeated hand in same combat
[PASS] 46. Thần Phản Chiếu (Blueprint) verified: dynamically copies deity to right across hand and card triggers
=== ALL SYSTEM TESTS PASSED SUCCESSFULLY! ===
`

---

*Chúc bạn có những phút giây trải nghiệm chiến thuật đỉnh cao, xây dựng đội quân bài thiện chiến và chinh phục thành công Tối Thượng Ma Thần tại Tầng 20!*
