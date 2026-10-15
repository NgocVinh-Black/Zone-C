# Zone-C

Desktop shell cho Hyprland, viết bằng Quickshell, của **NgocVinh-Black**.

**V2 (Frost)** là bản làm lại toàn bộ giao diện theo phong cách **Frost**: kính mờ, xanh băng, bo tròn, có cả nền tối và nền sáng.
Phím tắt và cách dùng quen thuộc của bản cũ được giữ nguyên; V2 đổi giao diện và thêm ứng dụng riêng.

## Có gì mới trong V2

- **Giao diện Frost** cho mọi thành phần: bar, launcher, thông báo, lịch, nhạc, mạng, âm lượng, màn hình khóa, OSD, menu nguồn.
- **Nền tối / sáng** và **6 màu nhấn** (Băng giá, Bầu trời, Bạc hà, Cát, Oải hương, Hồng phấn), đổi tức thì.
  Vẫn chọn được các bộ màu có sẵn (Zone Frost, Zone Thunder, Zone Crystal, Nord, Tokyo Storm, Mocha, Rose Pine, Gruvbox…)
  hoặc lấy màu từ hình nền (Matugen).
- **Tiếng Việt / tiếng Anh**: toàn bộ giao diện shell đổi ngôn ngữ trong Cài đặt → Ngôn ngữ.
- **Ứng dụng Cài đặt** mới với 27 trang: Wi-Fi, Bluetooth, màn hình, âm thanh, pin & nguồn, chuột & touchpad, bàn phím,
  bar, launcher, widget, thông báo, OSD, giao diện, ngôn ngữ, ngày giờ, người dùng, máy in, bộ nhớ, cập nhật,
  quyền riêng tư, trợ năng, sức khỏe số…
- **Ba ứng dụng riêng** viết bằng Quickshell, cùng giao diện Frost:
  - **Tệp**: trình quản lý file, kiêm hộp chọn file cho các ứng dụng khác (qua xdg-desktop-portal).
  - **Giám sát hệ thống**: tiến trình, CPU, RAM, ổ đĩa, mạng theo từng tiến trình.
  - **Cửa hàng ứng dụng**: tìm và cài từ pacman, AUR (yay / paru) và Flathub, có đánh giá sao, cập nhật một chỗ.
- **Tổng quan cửa sổ** (`Super + Tab`), **bảng emoji & ký tự** (`Super + .`), **quick actions** thu gọn ở cạnh màn hình.
- **Widget desktop** kéo thả được: đồng hồ (nhiều kiểu), thời tiết, nhạc, lịch hôm nay, pin, tài nguyên máy, khung ảnh,
  visualizer. Bấm chế độ sửa để thêm, xoá, đổi chỗ.
- **Bar** ngang (trên / dưới) hoặc dọc (trái / phải), chọn mô-đun hiển thị: workspace, nhạc, đồng hồ, thời tiết,
  CPU / RAM / nhiệt độ, mạng, Bluetooth, âm lượng, pin (có báo đang sạc), khay hệ thống, hẹn giờ, tiêu đề cửa sổ.
- **Viền cửa sổ đang dùng**: tĩnh, tia điện chạy quanh viền, hoặc tắt.
- **Chụp màn hình** kiểu Frost (`Super + Shift + Alt + S`), **bộ chọn chia sẻ màn hình** riêng khi gọi video / quay màn hình.
- **Màn hình khóa** và **màn đăng nhập SDDM** (`zone-frost`) cùng phong cách. Vẫn chọn lại được `zone-thunder`
  trong Cài đặt → Người dùng.
- **Trợ năng**: tương phản cao, cỡ chữ, phóng to màn hình (`Super + Alt + =` / `Super + Alt + −`).
- **Terminal foot** đổi sang bảng màu Frost.
- **Màn chào** lần đầu chạy để chọn ngôn ngữ, theme, chế độ tối / sáng và kiểu bar.
- Bỏ **Dock** và trang **Guide** cũ; `Super + H` giờ mở Cài đặt.

Vẫn giữ từ bản trước: gõ tiếng Việt bằng fcitx5 + Unikey, clipboard, lịch & thời tiết, trình phát nhạc có cava,
hình nền video, polkit, hộp xác nhận khi đóng cửa sổ, banner Zone-C + fastfetch khi mở terminal, gợi ý lệnh bằng ble.sh.

## Phím tắt chính

Xem đầy đủ bằng `Super + /`.

| Phím | Chức năng |
|---|---|
| `Super` (nhấn rồi thả) / `Super + D` | Launcher tìm ứng dụng, gõ `>` để chạy lệnh |
| `Super + /` | Bảng phím tắt |
| `Super + T` | Terminal (foot) |
| `Super + W` | Trình duyệt |
| `Super + E` | Trình quản lý file |
| `Super + I` / `Super + H` | Cài đặt |
| `Super + Tab` | Tổng quan cửa sổ |
| `Alt + Tab` | Chuyển sang cửa sổ kế tiếp |
| `Super + .` | Emoji & ký tự |
| `Super + V` | Lịch sử clipboard |
| `Super + M` / `Super + B` | Nhạc / bảng hệ thống |
| `Super + S` / `Super + N` | Lịch / mạng |
| `Super + Shift + W` | Chọn hình nền |
| `Super + Q` | Đóng cửa sổ (có hỏi xác nhận) |
| `Super + Shift + Q` | Đóng cửa sổ ngay |
| `Super + F` | Toàn màn hình |
| `Super + ←/→/↑/↓` | Chuyển cửa sổ |
| `Super + 1…0` | Sang workspace 1–10 |
| `Super + Page Up/Down` | Workspace trước / sau |
| `Super + L` | Khoá màn hình |
| `Print` | Chụp màn hình |
| `Super + Shift + S` | Chụp vùng (Flameshot) |
| `Super + Shift + Alt + S` | Chụp vùng (Zone-C) |
| `Super + Alt + R` | Quay màn hình |
| `Super + Alt + =` / `Super + Alt + −` | Phóng to / thu nhỏ màn hình |
| `Super + Shift + K` / phím Copilot | Bật / tắt bot AI float-cat |
| `Super + K` | Rồi kéo bot bằng chuột để dời chỗ |

Vuốt 3 ngón sang ngang trên touchpad để chuyển workspace. Vuốt 3 ngón lên để mở launcher hoặc tổng quan
thì bật trong Cài đặt → Chuột & touchpad.

## Bot AI float-cat (Claude Code)

Bot AI nổi ở góc màn hình, hiện trên mọi workspace, không chặn chuột: đầu tròn kiểu mũ phi hành gia có ăng-ten,
kính che mặt, hai mắt sáng và vòng cằm phát sáng. Nó lơ lửng, nheo mắt, chớp mắt, liếc nhìn, rảnh lâu thì nhắm mắt.
Màu lấy theo theme Frost (sáng / tối, màu nhấn) đang dùng.

Khi dùng [Claude Code](https://claude.com/claude-code), bot cho biết Claude đang làm gì:
mắt đảo đọc và ánh sáng chạy dọc vòng cằm khi đang chạy; mắt cười, vòng cằm xanh lá và dấu ✓ khi xong;
mắt mở to, vòng cằm vàng và "Cần bạn nè!" khi chờ bạn duyệt.

Script cài đặt chép bot vào `~/.local/share/float-cat` và lệnh `float-cat` vào `~/.local/bin`.
Để bot đi theo Claude Code, thêm các hook sau vào `~/.claude/settings.json` (gộp với `hooks` đang có):

```json
{
  "hooks": {
    "SessionStart":     [{ "hooks": [{ "type": "command", "command": "~/.local/bin/float-cat start" }] }],
    "SessionEnd":       [{ "hooks": [{ "type": "command", "command": "~/.local/bin/float-cat stop" }] }],
    "UserPromptSubmit": [{ "hooks": [{ "type": "command", "command": "~/.local/bin/float-cat say thinking" }] }],
    "PostToolUse":      [{ "hooks": [{ "type": "command", "command": "~/.local/bin/float-cat say thinking" }] }],
    "Notification":     [{ "hooks": [{ "type": "command", "command": "~/.local/bin/float-cat say ask" }] }],
    "Stop":             [{ "hooks": [{ "type": "command", "command": "~/.local/bin/float-cat say done" }] }]
  }
}
```

Không dùng Claude Code thì vẫn bật / tắt tay được: `float-cat toggle` hoặc `Super + Shift + K`.
Xoá `~/.local/state/float-cat/pos.json` để đưa bot về góc phải dưới.

## Cài đặt (Arch Linux và các bản dựa trên Arch)

V2 đang ở nhánh `feature-v2`. Clone đúng nhánh rồi chạy bộ cài từ thư mục đó:

```bash
git clone -b feature-v2 https://github.com/NgocVinh-Black/Zone-C.git
cd Zone-C
./install/install.sh
```

Bộ cài lấy mã từ chính thư mục đã clone. Lệnh cài nhanh bằng `curl` bên dưới luôn lấy nhánh `main`,
nên chỉ cài ra V2 sau khi `feature-v2` được gộp vào `main`:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/NgocVinh-Black/Zone-C/main/install/install.sh)"
```

Để cập nhật, chạy lại script và chọn "update". Cài đặt riêng của bạn trong `~/.config/zone-c/settings.json` được giữ lại.

Cấu hình mẫu cho các compositor khác (niri, sway) nằm trong thư mục [compositors](compositors).

## Giấy phép

Zone-C là tác phẩm phái sinh của [Serpantinum](https://github.com/ilyamiro/serpantinum) © ilyamiro,
phân phối theo [GNU AGPL-3.0](LICENSE.md).
Mọi bản phân phối lại hoặc chỉnh sửa tiếp theo cũng phải giữ giấy phép AGPL-3.0 và ghi công các tác giả.
