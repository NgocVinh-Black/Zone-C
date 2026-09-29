# Zone-C

Desktop shell cho Hyprland, viết bằng Quickshell, theo chủ đề **sấm sét xanh** — của **NgocVinh-Black**.

## Giao diện

- **Hình nền video sấm sét** động, logo và mascot mèo sấm Zone-C.
- **Viền điện** chạy quanh cửa sổ đang dùng (shader nhiễu trên GPU) kèm ánh sáng xanh.
- **Bar** ở cạnh trên (đổi được sang trái / phải / dưới): workspace, nhạc, đồng hồ, thời tiết, mạng,
  Bluetooth, âm lượng, pin và nút chuyển gõ tiếng Việt (`VI` / `US`).
- **Trình phát nhạc** có cột cava nhảy theo nhạc và hiệu ứng tia sét quét theo nhịp.
- **Launcher** tìm ứng dụng, gõ `>` để chạy lệnh. Tự tắt Unikey khi mở để gõ tìm kiếm.
- **Theme** có sẵn: *Zone Thunder* và *Zone Crystal*, đổi trong phần cài đặt.
- **Màn hình khóa** và **SDDM** (theme `zone-thunder`) cùng phong cách, nền video.
- **Hộp xác nhận đóng** cửa sổ theo theme, **bảng phím tắt** theo theme.
- Thông báo, clipboard, lịch, chụp / quay màn hình, quick actions, polkit.
- **Terminal foot** nền xanh navy trong suốt, banner Zone-C + fastfetch khi mở, gợi ý lệnh cũ từ lịch sử
  (ble.sh — nhấn `→` để nhận).
- **Gõ tiếng Việt** bằng fcitx5 + Unikey, icon Papirus-Dark.

## Phím tắt chính

| Phím | Chức năng |
|---|---|
| `Super` | Mở launcher |
| `Super + /` | Xem bảng phím tắt |
| `Super + T` | Terminal |
| `Super + W` | Trình duyệt |
| `Super + Q` | Đóng panel / đóng cửa sổ (có hỏi xác nhận) |
| `Super + Shift + Q` | Đóng cửa sổ ngay |
| `Super + Shift + S` | Chụp vùng màn hình |
| `Super + Alt + R` | Quay màn hình |
| `Super + F` | Toàn màn hình |
| `Super + ←/→/↑/↓` | Chuyển cửa sổ |
| `Super + Page Up/Down` | Chuyển workspace |

## Cài đặt (Arch Linux và các bản dựa trên Arch)

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/NgocVinh-Black/Zone-C/main/install/install.sh)"
```

Hoặc clone về rồi chạy:

```bash
git clone https://github.com/NgocVinh-Black/Zone-C.git
cd Zone-C
./install/install.sh
```

Để cập nhật, chạy lại script và chọn "update".

Cấu hình mẫu cho các compositor khác (niri, sway) nằm trong thư mục [compositors](compositors).

## Giấy phép

Zone-C là tác phẩm phái sinh của [Serpantinum](https://github.com/ilyamiro/serpantinum) © ilyamiro,
phân phối theo [GNU AGPL-3.0](LICENSE.md).
Mọi bản phân phối lại hoặc chỉnh sửa tiếp theo cũng phải giữ giấy phép AGPL-3.0 và ghi công các tác giả.
