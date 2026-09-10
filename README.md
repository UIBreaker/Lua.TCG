# 🃏 LUA.TCG - POKER ROGUELIKE DECKBUILDER

> Một tựa game thẻ bài chiến thuật Poker Roguelike phong cách Deck-building cổ điển, lấy cảm hứng từ *Balatro* kết hợp yếu tố nhập vai diệt quái, độ bền vũ khí và khảm ngọc trang bị độc đáo. Game được viết hoàn toàn bằng **Lua** và vận hành trên nền tảng **LÖVE 2D (Love2D v11.5)**.

[![GitHub Repository](https://img.shields.io/badge/GitHub-UIBreaker%2FLua.TCG-blue?logo=github)](https://github.com/UIBreaker/Lua.TCG.git)
[![Engine](https://img.shields.io/badge/Engine-LÖVE%2011.5-pink?logo=lua)](https://love2d.org/)
[![Tests](https://img.shields.io/badge/Tests-24%2F24%20Passing-brightgreen)](test_system.lua)

---

## 📑 MỤC LỤC
1. [Khởi Chạy Nhanh](#-khởi-chạy-nhanh)
2. [Cơ Chế Khởi Đầu Trò Chơi](#-1-cơ-chế-khởi-đầu-trò-chơi)
3. [Bản Đồ Hành Trình 20 Tầng (Act 1 Map)](#-2-bản-đồ-hành-trình-20-tầng)
4. [Cơ Chế Chiến Đấu & Máu Quái Vật](#-3-cơ-chế-chiến-đấu--máu-quái-vật)
5. [Hệ Thống Độ Bền & Suy Hao Thẻ Bài](#-4-hệ-thống-độ-bền--suy-hao-thẻ-bài)
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
- **Cách 1 (Nhanh nhất)**: Nhấp đúp chuột vào file `run.bat` trong thư mục gốc.
- **Cách 2 (Dòng lệnh)**:
  ```powershell
  ..\love-11.5-win64\love.exe .
  ```
- **Chế độ Fullscreen tràn viền**: Nhấn phím **`F11`** bất kỳ lúc nào để chuyển đổi chế độ Toàn Màn Hình tràn viền. Game sử dụng Canvas ảo độ phân giải gốc $1280 \times 720$, tự động co giãn sắc nét và căn giữa mượt mà trên mọi kích thước màn hình.

---

## 🎴 1. Cơ Chế Khởi Đầu Trò Chơi

Khi bắt đầu một lượt chơi mới tại Menu chính:
1. **Lựa chọn Hệ Chất Khởi Đầu**: Người chơi chọn 1 trong 4 chất bài đại diện cho trường phái:
   - **Cơ (Hearts ♥)**: Sắc thái Đỏ rực, chuyên buff sát thương nhân (Mult).
   - **Rô (Diamonds ♦)**: Sắc thái Cam vàng, gia tăng tích lũy kinh tế và điểm Chips.
   - **Chuồn (Clubs ♣)**: Sắc thái Xanh lục bảo, cân bằng kiểm soát bài và lượt đổi.
   - **Bích (Spades ♠)**: Sắc thái Xanh bóng đêm, mang sức mạnh nhân bội số tối thượng (XMult).
2. **Bộ bài ban đầu thuần chất (Chỉ có 3 lá bài ngẫu nhiên)**:
   - Thay vì cầm cả bộ bài 52 lá như thông thường, người chơi bắt đầu hành trình với **chính xác 3 lá bài ngẫu nhiên** thuộc chất đã chọn (ví dụ: `K♣, 7♣, 3♣`).
   - Mọi lá bài mới thuộc các chất khác chỉ có thể thu thập thêm trong quá trình thám hiểm thông qua Rương báu, Cửa hàng hoặc Sự kiện.
3. **Không có Thần Bài hỗ trợ ban đầu**:
   - Khởi đầu cuộc hành trình với hai bàn tay trắng (0 vị thần).
   - Các Thần Bài hùng mạnh chỉ có thể được thỉnh sau khi bạn đánh bại các Trùm Cuối (Boss).
4. **Giới hạn thế đánh ban đầu**:
   - Bạn chỉ được phép đánh **1 lá đơn lẻ (ĐƠN THỦ - High Card)**. Toàn bộ các thế bài cao cấp hơn bắt buộc phải mở khóa thông qua Sách Bí Tịch.

---

## 🗺️ 2. Bản Đồ Hành Trình 20 Tầng

Hành trình Vùng Đất 1 (Act 1) được tạo ngẫu nhiên theo đồ thị phân nhánh gồm **20 tầng thử thách**:

| Biểu tượng | Loại Địa Điểm | Ý Nghĩa & Phần Thưởng |
| :---: | :--- | :--- |
| ⚔️ | **Màn Thường (Monster)** | Gặp quái vật rừng sâu. Chiến thắng nhận Vàng thưởng và mở đường đi tiếp. |
| 👹 | **Màn Tinh Anh (Elite)** | Quái vật đột biến hung bạo. Đánh bại sẽ được mở Rương Cổ Vật nhận bài hiếm hoặc trang bị. |
| 🛍️ | **Cửa Hàng (Shop)** | Mua Sách Bí Tịch mở thế bài, mua Trang bị, Phù chú tiếp lực và hoán đổi trang bị giữa các lá bài. |
| 🏕️ | **Trạm Nghỉ (Rest Site)** | Lựa chọn giữa: **Dưỡng Sức** (+1 Lượt Đánh & +1 Lượt Đổi tối đa) hoặc **Tôi Luyện Lò Rèn** (+1 Rank vĩnh viễn cho 1 lá bài). |
| 🎁 | **Rương Báu (Treasure)** | Nhận miễn phí 1 trong 3 phần quà: Lá bài tiếp viện chỉ số cao hoặc Cổ vật trang bị. |
| ❓ | **Sự Kiện (Event)** | Gặp các nhân vật thần bí (Tiên Tri Thần Bài, Đền Cổ Bị Lãng Quên,...) mang lại cơ duyên bất ngờ. |
| 👑 | **Trùm Cuối (Boss)** | Tầng 20: Đối đầu Tối Thượng Ma Thần. Chiến thắng sẽ triệu hồi 2 Vị Thần để bạn chọn 1. |

- **Cuộn bản đồ**: Sử dụng con lăn chuột (`Mouse Wheel`) để cuộn mượt mà xem trước lộ trình từ Tầng 1 đến Tầng 20.

---

## ⚔️ 3. Cơ Chế Chiến Đấu & Máu Quái Vật

- **Máu Quái Vật (Monster HP)**:
  - Thay vì chỉ tính điểm trừu tượng, điểm số bài đánh ra được quy đổi thành **Sát thương vật lý trực tiếp** trừ vào thanh máu của quái vật.
  - Quái vật đầu tiên (Tầng 1) chỉ có **30 HP**, hoàn toàn cân bằng với bộ bài 3 lá khởi đầu.
  - Máu quái vật tăng dần theo tầng, quái Tinh anh sở hữu lượng máu dồi dào, và Trùm Cuối Tầng 20 sở hữu **650 HP** cùng hiệu ứng debuff đặc thù (như khống chế tối đa 4 lá bài/lượt).
- **Tài Nguyên Trong Mỗi Màn**:
  - **Lượt Đánh (Hands)**: Mặc định 4 lượt. Hết lượt đánh mà chưa hạ gục quái vật sẽ thua trận (Game Over).
  - **Lượt Đổi Bài (Discards)**: Mặc định 3 lượt để xáo bài mới.
- **Công Thức Tính Sát Thương**:
  $$\text{Sát Thương} = \left( \sum \text{Chips}_{\text{Cơ bản}} + \sum \text{Chips}_{\text{Trang bị}} + \sum \text{Chips}_{\text{Thần}} \right) \times \left( \text{Mult}_{\text{Cơ bản}} + \text{Mult}_{\text{Buff}} \right) \times \prod \text{XMult}$$

---

## 🔨 4. Hệ Thống Độ Bền & Suy Hao Thẻ Bài

Điểm nhấn cơ chế sáng tạo độc nhất: **Thẻ bài bị hao mòn độ bền qua từng lần đánh ra**:

1. **Quy tắc trừ Rank khi xuất chiêu**:
   - Mỗi lần một lá bài được chọn để đánh ra ghi điểm, số của lá bài đó sẽ **giảm đi 1**:
     $$K (13) \rightarrow Q (12) \rightarrow J (11) \rightarrow 10 \rightarrow \dots \rightarrow 2 \rightarrow A (1)$$
   - Rank của lá bài vừa là giá trị chip cơ bản, vừa chính là **số lần sử dụng còn lại** của lá bài đó trong trận đấu!
2. **Lá Át (A) vỡ vụn**:
   - Lá Át ($A = 1$) là ngưỡng bền cuối cùng. Nếu bạn đánh lá Át ra sân, lá bài sẽ **vỡ vụn và tiêu biến hoàn toàn** khỏi cọc bài trong phần còn lại của trận đấu đó.
3. **Khôi phục như ban đầu khi qua trận mới**:
   - Khi trận chiến kết thúc (quái vật bị tiêu diệt) và bạn bước sang một nút mới trên bản đồ: **Toàn bộ các lá bài trong bộ bài sẽ được tự động khôi phục hoàn toàn về Rank cơ sở (`baseRank`) ban đầu** cùng tất cả trang bị đã khảm!
   - Thẻ bài bị vỡ vụn cũng sẽ hồi sinh nguyên vẹn cho trận kế tiếp.
4. **Tôi Luyện Vĩnh Viễn Tại Lò Rèn**:
   - Khi ghé thăm Trạm Nghỉ Chân và chọn Tôi Luyện: 1 lá bài được chọn sẽ tăng vĩnh viễn $+1$ Rank cơ sở (ví dụ: lá $5$ tôi luyện lên lá $6$), giúp tăng Chips và tăng số lần đánh cho mọi trận đấu tương lai.

---

## 📖 5. Hệ Thống Mở Khóa Thế Đánh & Sổ Tay Bí Tịch

Mới vào game, người chơi **chỉ đánh được thế bài 1 lá (ĐƠN THỦ)**. Để tung ra các tuyệt kỹ nhiều lá, bạn phải thu thập các **Sách Bí Tịch**:

| STT | Thế Bài Poker | Tên Tiếng Việt | Số Lá | Chỉ Số Cơ Bản | Sách Bí Tịch Tương Ứng |
| :---: | :--- | :--- | :---: | :---: | :--- |
| 1 | **High Card** | ĐƠN THỦ | 1 | $5 \text{ Chips} \times 1 \text{ Mult}$ | *Mở khóa sẵn từ đầu game* |
| 2 | **Pair** | SONG ĐAO (Đôi) | 2 | $10 \text{ Chips} \times 2 \text{ Mult}$ | Bí Tịch: Song Đao Quyết ($4) |
| 3 | **Two Pair** | SONG ĐÔI (Hai Đôi) | 4 | $20 \text{ Chips} \times 2 \text{ Mult}$ | Bí Tịch: Song Tinh Hợp Bích ($4) |
| 4 | **Three of a Kind** | TAM HOA (Sám Cô) | 3 | $30 \text{ Chips} \times 3 \text{ Mult}$ | Bí Tịch: Tam Hoa Tụ Đỉnh ($5) |
| 5 | **Straight** | TRƯỜNG LONG (Sảnh) | 5 | $30 \text{ Chips} \times 4 \text{ Mult}$ | Bí Tịch: Trường Long Xuất Hải ($6) |
| 6 | **Flush** | ĐỒNG KHÍ (Thùng) | 5 | $35 \text{ Chips} \times 4 \text{ Mult}$ | Bí Tịch: Đồng Khí Quy Tâm ($6) |
| 7 | **Full House** | HỖN NGUYÊN (Cù Lũ) | 5 | $40 \text{ Chips} \times 4 \text{ Mult}$ | Bí Tịch: Hỗn Nguyên Nhất Thể ($7) |
| 8 | **Four of a Kind** | TỨ TƯỢNG (Tứ Quý) | 4 | $60 \text{ Chips} \times 7 \text{ Mult}$ | Bí Tịch: Tứ Tượng Trận Đồ ($8) |
| 9 | **Straight Flush** | VẠN KIẾM QUY TÔNG | 5 | $100 \text{ Chips} \times 8 \text{ Mult}$ | Bí Tịch: Vạn Kiếm Quy Tông ($10) |

- **Thuật toán nhận diện thông minh**: Nếu bạn đánh ra 5 lá bài thỏa mãn Thùng Phá Sảnh nhưng chưa mở khóa thế bài này, hệ thống sẽ tự động hạ cấp xuống thế bài hợp lệ cao nhất bạn đã mở (Sảnh hoặc Thùng), bảo đảm không bao giờ bị mất lượt oan!
- **Sổ Tay Bí Tịch (`SỔ TAY [H]`)**: Nhấn phím **`H`** hoặc click nút `SỔ TAY [H]` để xem nhanh trạng thái mở khóa của tất cả 9 thế bài.

---

## 💎 6. Hệ Thống Khảm Trang Bị Vào Lá Bài (Socketing)

Mỗi lá bài trong bộ bài sở hữu **tối đa 5 ô khảm trang bị (Sockets)**. Các trang bị mang lại hiệu ứng độc đáo khi lá bài được kích hoạt:

1. 💎 **Đá Lửa**: $+35$ Chips trực tiếp cho lá bài này khi tính điểm.
2. 🔥 **Đá Bùng Nổ**: $+10$ Mult cho toàn bộ tay bài khi lá này ghi điểm.
3. 🪞 **Gương Lan Tỏa**: Buff $+25$ Chips cho 2 lá bài nằm kế bên khi đánh ra.
4. 🌪️ **Mắt Bão**: $+3$ Mult cho tất cả các lá bài CÙNG CHẤT trong tay bài.
5. 💰 **Đồng Tiền May Mắn**: Thưởng ngay $+\$3$ Vàng khi lá bài ghi điểm.
6. 🪶 **Lông Vũ Tự Do**: Khi Đổi bài (Discard) lá này, KHÔNG bị trừ lượt đổi bài.
7. 🩸 **Nhẫn Huyết Thần**: Khi lá này ghi điểm, gây thêm $15\%$ sát thương chuẩn trừ thẳng vào máu quái.
8. 👑 **Ngọc Bội Thánh Tích**: Nhân trực tiếp $\times 1.3$ XMult vào tổng sát thương.

> 💡 **Mẹo**: Nhấp **Chuột Phải** vào bất kỳ lá bài nào trên tay hoặc trong kho để phóng to hình ảnh, xem số lần sử dụng còn lại và thông tin chi tiết từng món đồ đã khảm!

---

## 🏪 7. Cửa Hàng Lữ Khách & Hoán Đổi Trang Bị

- **Mua Sắm**:
  - Mua Sách Bí Tịch để mở khóa thế đánh mới.
  - Mua Trang Bị Cổ Vật và khảm trực tiếp vào 1 lá bài trong kho bài.
  - Mua Phù Chú Tiếp Lực ($+1$ Lượt Đánh & $+1$ Lượt Đổi bài tức thì).
  - Mua Lá Bài Tiếp Viện (bổ sung bài chất lạ hoặc rank cao).
  - Làm mới hàng bán (Reroll) với giá $\$3$.
- **Hoán Đổi Trang Bị (Shop Transfer)**:
  - Cho phép tháo trang bị từ lá bài này để chuyển sang lá bài khác ngay tại Cửa Hàng:
    1. Chọn lá bài nguồn đang có trang bị.
    2. Chọn ô trang bị muốn tháo.
    3. Chọn lá bài đích để lắp vào (tối đa 5 ô/lá).

---

## 👑 8. Hệ Thống Thần Bài Ban Ơn (Deities)

- Các vị Thần Bài **không thể mua trong shop**. Bạn chỉ có cơ hội diện kiến Thần Bài khi đánh bại Trùm Cuối (Boss Tầng 20) hoặc mở các hòm báu cực hiếm.
- Mỗi lần chiến thắng Boss, 2 Vị Thần Bài ngẫu nhiên xuất hiện, bạn được chọn **1 trong 2**:
  - **Thần Cặp Đôi**: Mỗi Đôi ghi điểm $+15$ Mult.
  - **Thần Tam Hoa**: Mỗi Sám cô ghi điểm $+30$ Mult.
  - **Thần Sảnh**: Mỗi khi đánh Sảnh nhân $\times 2.0$ XMult.
  - **Thần Thùng**: Mỗi lá bài trong Thùng $+15$ Chips.
  - **Thần Át Chủ Bài**: Mỗi lá Át trên tay $+20$ Mult.
  - **Thần Bùng Nổ**: Khi còn 1 Lượt đánh duy nhất, nhân $\times 2.0$ XMult.
  - **Thần Vương Giả**: Mỗi lá J, Q, K ghi điểm $+10$ Mult.
  - **Thần Tiết Kiệm**: Cuối round nhận $+\$1$ vàng cho mỗi $\$5$ đang sở hữu.
- Người chơi có thể sở hữu tối đa 5 vị Thần và có thể bán lại trong Cửa Hàng khi cần đổi chiến thuật.

---

## 🗃️ 9. Bảng Toàn Bộ Bộ Bài (Deck Viewer [Tab])

Bấm phím **`Tab`** bất cứ lúc nào (trong trận chiến hoặc ngoài bản đồ) để mở Bảng Tổng Quan:
- Xem tổng số lá bài hiện có trong bộ bài.
- Thống kê tỷ lệ các chất (Cơ, Rô, Chuồn, Bích).
- Bộ lọc nhanh: Tất cả, Từng chất, hoặc Chỉ các lá đã khảm trang bị.
- Danh mục chi tiết các bí tịch và trạng thái đã mở khóa bên cột phải.

---

## ⌨️ 10. Bảng Phím Tắt Toàn Tập

| Phím Tắt | Chức Năng |
| :---: | :--- |
| **`F11`** | Bật / Tắt chế độ Toàn màn hình tràn viền (Fullscreen borderless). |
| **`H`** | Mở / Đóng nhanh **Sổ Tay Các Thế Bài Poker** (Handbook). |
| **`Tab`** | Mở / Đóng **Toàn Bộ Bộ Bài & Bí Tịch** (Deck Viewer). |
| **`Chuột Phải`** | Nhấp vào lá bài để mở bảng **Soi Chi Tiết Trang Bị & Độ Bền**. |
| **`Space`** hoặc **`Enter`** | Tấn Công (Đánh tay bài đã chọn) / Tua nhanh hoạt ảnh tính điểm. |
| **`D`** | Đổi Bài (Discard các lá bài đã chọn). |
| **`R`** | Sắp xếp các lá bài trên tay theo Rank (Số: K $\rightarrow$ A). |
| **`S`** | Sắp xếp các lá bài trên tay theo Suit (Chất: Cơ $\rightarrow$ Rô $\rightarrow$ Chuồn $\rightarrow$ Bích). |
| **`Phím 1 .. 8`** | Bật/tắt chọn nhanh lá bài tương ứng từ 1 đến 8 trên tay. |
| **`Cuộn Chuột`** | Cuộn camera di chuyển trên Bản Đồ 20 tầng. |
| **`Esc`** | Đóng cửa sổ modal / Bảng thông tin đang mở. |

---

## 📂 11. Cấu Trúc Thư Mục & Mã Nguồn

```text
poker-roguelike/
├── conf.lua               # Cấu hình cửa sổ LÖVE 2D (1280x720, VSync, Tiêu đề)
├── main.lua               # Vòng lặp chính, quản lý Game State, Renderer và Input
├── run.bat                # Kịch bản khởi chạy game nhanh 1-click
├── test_system.lua        # Bộ kiểm thử tự động toàn diện 24 bài test
├── fonts/                 # Bộ phông chữ hỗ trợ tiếng Việt Unicode hoàn chỉnh
└── src/
    ├── deck.lua           # Xử lý bài, cọc bài, suy hao độ bền, khôi phục rank
    ├── deities.lua        # Hệ thống Thần bài, nội tại buff, draft sau khi diệt Boss
    ├── equipment.lua      # 8 loại trang bị, cơ chế khảm ngọc 5 ô, tính toán hiệu ứng
    ├── events.lua         # Hệ thống sự kiện ngẫu nhiên trên bản đồ
    ├── map.lua            # Thuật toán sinh bản đồ 20 tầng phân nhánh và cuộn camera
    ├── monster.lua        # Chỉ số quái thường, quái tinh anh và trùm cuối (HP & Debuff)
    ├── poker.lua          # Thuật toán đánh giá 9 thế bài poker & phân cấp thông minh
    ├── scoring.lua        # Bộ tính điểm theo bước (Chips x Mult x XMult) và hoạt ảnh
    ├── shop.lua           # Cửa hàng lữ khách, sách bí tịch, mua bán thần bài & chuyển đồ
    ├── sound.lua          # Bộ phát âm thanh giao diện và hiệu ứng chiến đấu
    └── ui.lua             # Thư viện vẽ UI, thẻ bài, huy hiệu, tooltip và bảng màu
```

---

## 🧪 12. Kiểm Thử Tự Động

Game tích hợp bộ kiểm thử tự động 24 bài test độc lập để đảm bảo độ ổn định tuyệt đối:
```powershell
..\love-11.5-win64\love.exe . --test
```
Kết quả kiểm thử:
```text
=== RUNNING ROGUELIKE POKER SYSTEM TESTS ===
[PASS] 1. Floor 1 Monster HP is 30 HP: Yêu Tinh Rừng Xanh (30 HP)
[PASS] 2. Floor 20 Boss created successfully: TỐI THƯỢNG MA THẦN (650 HP)
[PASS] 3. Starter 1-card evaluation is High Card: ĐƠN THỦ
[PASS] 4. Locked hand attempt detected and gracefully downgraded to High Card
[PASS] 5. Unlocking Song Đao allows Pair evaluation: SONG ĐAO
[PASS] 6. Act 1 Map generated with 20 floors, starter nodes available, boss on Floor 20
[PASS] 7. Map node completion unlocks connecting nodes properly
[PASS] 8. Boss Deity draft offers 2 distinct deities: Thần Bùng Nổ and Thần Đại Dương
[PASS] 9. Shop sells Skill Books and successfully unlocks hand: four_of_a_kind
[PASS] 10. Selling deity refunds gold properly
[PASS] 11. Starter deck has exactly 3 random cards of chosen suit: 3 cards
[PASS] 12. Card degradation system verified: 5 -> 4 -> 3 -> 2 -> A -> DESTROYED
[PASS] 13. Equipment transfer between cards verified successfully
[PASS] 14. Deities.addDeity successfully adds chosen deity: Thần Bùng Nổ
[PASS] 15. Encounter deck restoration verified: cards restore to initial rank in new encounter
[PASS] 16. Card addition adds strictly to deck and not hand (prevents duplicate selection bug)
[PASS] 17. Unlocked Straight correctly plays as Straight despite sharing same suit: TRƯỜNG LONG
[PASS] 18. Handbook contains all 9 poker hands ordered by rank for Compendium view
[PASS] 19. Deck.addCardToDeck safely adds 1 card and blocks duplicates: 4 total cards
[PASS] 20. Deck.cloneCard preserves exact card id for 1:1 combat tracking
[PASS] 21. Equipment attaches to persistent deck card and clones correctly into combat
[PASS] 22. Hand card selection isolates strictly to the chosen card (no 2-card selection bug)
[PASS] 23. Deck restoration across battles maintains baseRank and equipments
[PASS] 24. Shop equipment purchase and socketing attaches properly without being erased
=== ALL 24 SYSTEM TESTS PASSED SUCCESSFULLY! ===
```

---

*Phát triển bởi đội ngũ đam mê Poker Deckbuilders. Chúc bạn có những phút giây trải nghiệm thú vị và chinh phục thành công Tối Thượng Ma Thần tại Tầng 20!*
