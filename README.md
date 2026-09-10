# Poker Roguelike Demo (LÖVE v11.5.0)

Bản demo game thẻ bài Poker Roguelike theo phong cách deck-building (tương tự Balatro) được viết bằng **Lua** và chạy trên nền tảng **LÖVE 2D (v11.5.0)**.

---

## 🃏 Cách Khởi Chạy Game

1. **Cách nhanh nhất**: Nhấp đúp chuột vào file `run.bat` trong thư mục này.
2. **Hoặc bằng dòng lệnh**:
   ```powershell
   ..\love-11.5-win64\love.exe .
   ```

---

## 🎮 Hướng Dẫn Chơi

### 1. Chọn Chất Bài Khởi Đầu (Menu)
Tại menu chính, người chơi lựa chọn 1 trong 4 chất bài để định hình phong cách và nhận Thần bảo trợ khởi đầu:
- **Cơ (Hearts ♥)**: Nhận *Thần Lửa Cơ* (`+4 Mult` cho mỗi lá Cơ ghi điểm) - Lối chơi tăng hệ số nhân (Mult).
- **Rô (Diamonds ♦)**: Nhận *Thần Đất Rô* (`+25 Chips` cho mỗi lá Rô & `+$2` vàng sau mỗi Round) - Tích lũy kinh tế mạnh mẽ.
- **Chuồn (Clubs ♣)**: Nhận *Thần Gió Chuồn* (`+1 Discard` mỗi round & `+30 Chips` mọi tay bài) - Kiểm soát bài ổn định.
- **Bích (Spades ♠)**: Nhận *Thần Đêm Bích* (`x1.5 XMult` khi bài có Bích) - Nhân bùng nổ điểm số cuối cùng.

### 2. Mục Tiêu & Cơ Chế Vòng Chơi (Round Loop)
- Mỗi Round đặt ra một mốc **Mục tiêu Chip** cần đạt (ví dụ: Round 1 là 300 Chips, Round 2 là 750 Chips,...).
- Bạn có:
  - **4 Lượt Đánh (Hands)**
  - **3 Lượt Đổi Bài (Discards)**
- Trên tay có 8 lá bài, bạn chọn từ **1 đến 5 lá bài** để Đánh hoặc Đổi.
- Khi chọn bài, hệ thống sẽ tự động xem trước (Preview) loại tay bài Poker và điểm số dự kiến.

### 3. Công Thức Tính Điểm
$$\text{Điểm} = (\text{Chips cơ bản} + \text{Chips cộng thêm}) \times (\text{Mult cơ bản} + \text{Mult cộng thêm}) \times (\text{Hệ số XMult})$$
- **Chips lá bài**: Át = 11, J/Q/K = 10, 2-10 = giá trị trên lá bài.
- **9 loại tay bài chuẩn**:
  1. High Card (Mậu thầu): 5 Chips, 1 Mult
  2. Pair (Đôi): 10 Chips, 2 Mult
  3. Two Pair (Hai đôi): 20 Chips, 2 Mult
  4. Three of a Kind (Sám cô): 30 Chips, 3 Mult
  5. Straight (Sảnh): 30 Chips, 4 Mult (Át tính linh hoạt đầu sảnh A-2-3-4-5 hoặc cuối sảnh 10-J-Q-K-A)
  6. Flush (Thùng): 35 Chips, 4 Mult
  7. Full House (Cù lũ): 40 Chips, 4 Mult
  8. Four of a Kind (Tứ quý): 60 Chips, 7 Mult
  9. Straight Flush (Thùng phá sảnh): 100 Chips, 8 Mult
- **XMult (Nhân bùng nổ)**: Ký hiệu $\times 1.5, \times 2.0$, nhân trực tiếp ở bước cuối cùng sau khi đã nhân Chips với Mult.

### 4. Cửa Hàng Thần Bài (Deities Shop)
- Sau khi vượt qua mỗi Round, bạn sẽ nhận được Tiền thưởng ($).
- Vào Cửa hàng để:
  - Mua các lá Thần bài mới (Tối đa 5 ô trang bị).
  - Bán các Thần bài cũ để lấy lại một nửa giá trị.
  - Làm mới (Reroll) danh sách hàng bán với giá $2.
  - Nhấn `Tiếp tục Round tiếp theo` để sang màn chơi mới với độ khó tăng dần.

---

## ⌨️ Phím Tắt Tiện Lợi
- `Chuột trái`: Chọn / Bỏ chọn bài, nhấn các nút bấm trên giao diện.
- `Phím Space` hoặc `Enter`: Đánh bài (Play Hand).
- `Phím D`: Đổi bài (Discard).
- `Phím R`: Sắp xếp bài theo Số (Rank: A -> 2).
- `Phím S`: Sắp xếp bài theo Chất (Suit: Cơ -> Rô -> Chuồn -> Bích).
- `Phím số 1..8`: Bật/tắt chọn nhanh lá bài từ 1 đến 8 trên tay.
