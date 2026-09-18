# Zone-C

Shell desktop cá nhân cho **Hyprland**, viết bằng **Quickshell**.

- Kiến trúc: **Core + Features + Slots**. Mỗi tính năng là một thư mục khép kín trong `features/`.
- Giao diện: theo Serpantinum v1 (ảnh chụp ngày 07/04/2026), gồm thanh bar là các khối nổi, các popup nhạc, lịch, mạng, âm lượng, pin, và bảng màu tối lấy từ ảnh v1.

Thiết kế đầy đủ: [2026-09-17-zone-c-design.md](2026-09-17-zone-c-design.md)

## Trạng thái

| Giai đoạn | Nội dung | Trạng thái |
|---|---|---|
| 1. Core | config, theme, scale, Hypr, ui, feature loader, bar, popup host, check, tests | ✅ |
| 2. Bar | workspaces, media, clock, weather, tray, keyboard, network, bluetooth, volume, battery | ✅ |
| 3. Giao diện v1 + popup | nút tìm kiếm/chuông, popup nhạc (+ equalizer), lịch, mạng, âm lượng, pin | 🧪 code xong, chưa chạy thử |
| 4. Popup giữa + hệ thống | launcher, clipboard, notifications, OSD | ⏳ |
| 5. Hoàn thiện | lock, wallpaper + matugen, settings | ⏳ |

## Cài đặt trên Arch mới

Sau khi cài Arch (có mạng, có user thường dùng được `sudo`):

```bash
sudo pacman -S --needed git
git clone <url-repo-của-bạn> ~/Projects/Zone-C
cd ~/Projects/Zone-C
./install.sh
```

`install.sh` hỏi trước mỗi bước (thêm `--yes` để bỏ hỏi, `--dry-run` để xem trước):

1. Cài gói từ repo Arch; `quickshell`, `matugen` lấy từ AUR nếu repo không có (tự cài `yay` khi cần).
2. Tạo symlink: repo → `~/.config/quickshell/zone-c`, và `dotfiles/` → `~/.config/{hypr,kitty,rofi,matugen,swaync}`, `~/.zshrc`, `~/.local/bin/zone-c-wallpaper`. Config cũ được chuyển vào `~/.local/state/zone-c/backup-<thời gian>/`.
3. Tạo `~/.config/zone-c/shell.json` và bảng màu mặc định trong `~/.cache/zone-c/`.
4. Bật NetworkManager, bluetooth, power-profiles-daemon; hỏi bật SDDM và đổi shell sang zsh.

Xong thì đăng xuất (hoặc khởi động lại) và chọn phiên **Hyprland**. Bỏ ảnh vào `~/Pictures/Wallpapers` rồi bấm `SUPER+W` để chọn hình nền: bar, popup, viền cửa sổ, kitty, rofi, swaync đổi màu theo ảnh (matugen).

Vì là symlink, `git pull` trong repo là cập nhật luôn cả shell lẫn dotfiles. Chỉnh riêng cho từng máy (màn hình, layout bàn phím) đặt trong `~/.config/hypr/local.conf`, file này không vào git.

## Phím tắt chính

| Phím | Việc |
|---|---|
| `SUPER+Enter` / `SUPER+Space` | kitty / tìm ứng dụng (rofi) |
| `SUPER+Q` / `SUPER+F` / `SUPER+SHIFT+F` | đóng / toàn màn hình / nổi cửa sổ |
| `SUPER+1…8`, `SUPER+SHIFT+1…8` | chuyển / chuyển cửa sổ sang workspace |
| `SUPER+M` / `C` / `A` / `P` | popup nhạc / lịch / âm lượng / pin |
| `SUPER+SHIFT+N` / `SUPER+SHIFT+B` | popup mạng tab Wi-Fi / Bluetooth |
| `SUPER+N` / `SUPER+V` / `SUPER+W` | thông báo / lịch sử clipboard / chọn hình nền |
| `SUPER+L` / `SUPER+SHIFT+E` | khoá màn hình / thoát Hyprland |
| `Print` / `SHIFT+Print` | chụp vùng vào clipboard / chụp cả màn hình vào `~/Pictures/Screenshots` |
| `SUPER+SHIFT+R` | khởi động lại shell |

Toàn bộ ở `dotfiles/hypr/conf/keybindings.conf`.

## Chạy tay (xem log)

```bash
pkill -x qs; qs -c zone-c
```

Quickshell tự reload khi bạn sửa file. Mở popup từ terminal: `qs -c zone-c ipc call popup toggle battery ""`.

## Cấu hình

File: `~/.config/zone-c/shell.json` (install.sh tạo từ `config/shell.example.json`). Thiếu hoặc sai giá trị nào thì dùng mặc định, và cảnh báo được ghi trong log của `qs`. File được theo dõi, nên lưu là áp dụng ngay.

- `bar.left` / `bar.center` / `bar.right`: danh sách **nhóm**. Mỗi nhóm là một khối nổi, gồm tên các feature.
- `features.<tên>`: cấu hình riêng của từng feature (xem `features/<tên>/schema.js`), ví dụ lệnh của nút tìm kiếm, chuông, khoá máy, tắt máy.
- `weather`: đơn vị và toạ độ (bỏ trống thì định vị theo IP). Dùng chung cho widget thời tiết và popup lịch.
- `features.clock.scheduleCommand`: lệnh tuỳ chọn in lịch học dạng JSON để hiện ở đáy popup lịch (xem `features/clock/schema.js`).
- `theme.matugen: true`: đọc màu từ `~/.cache/zone-c/colors.json` do `zone-c-wallpaper` sinh ra; chưa chọn hình nền thì dùng bảng màu mặc định.

## Kiểm tra

```bash
bash tools/check.sh    # quy tắc kiến trúc R1–R7 + unit test
npm test               # chỉ unit test
```

## Thêm một feature

1. Tạo `features/<tên>/feature.qml`:
   ```qml
   import QtQuick
   import qs.core.feature

   Feature {
       name: "<tên>"
       barWidget: Qt.resolvedUrl("<Tên>Widget.qml")
   }
   ```
2. Dữ liệu hệ thống đặt trong `<Tên>Service.qml` (`pragma Singleton`). Chỉ file `*Service.qml` được chạy lệnh ngoài.
3. Widget kế thừa `BarWidget` (`import qs.core.bar`). Đặt `shown` thay vì `visible`, và dùng `Tokens` / `Colours` thay cho số và màu viết cứng.
4. Thêm tên feature vào `bar` trong `shell.json`.
5. Chạy `bash tools/check.sh`.

## Quy tắc

| # | Quy tắc |
|---|---|
| R1 | Chỉ `*Service.qml` và `core/services/` được dùng `Process`, `execDetached`, `hyprctl` |
| R2 | Không màu viết cứng ngoài `core/theme/` |
| R3 | Không đọc config thô ngoài `core/config/` |
| R4 | `core/` không import `features`; feature không import feature khác |
| R5 | File QML tối đa 400 dòng |
| R6 | Mỗi feature có `feature.qml` hợp lệ; unit test qua |
| R7 | `qmllint` (chỉ báo, không chặn) |
