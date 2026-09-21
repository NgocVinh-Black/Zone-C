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
| 3. Giao diện v1 + popup | nút tìm kiếm/chuông, popup nhạc (+ equalizer), lịch, mạng, âm lượng, pin | 🧪 code xong, shell khởi động sạch, chưa soi từng popup |
| 4. Popup giữa + hệ thống | launcher, clipboard, notifications (toast + trung tâm), OSD âm lượng | ✅ |
| 5. Hoàn thiện | lock, settings | ⏳ |

## Cài đặt trên Arch mới

Sau khi cài Arch (có mạng, có user thường dùng được `sudo`):

```bash
sudo pacman -S --needed git
git clone <url-repo-của-bạn> ~/Projects/Zone-C
cd ~/Projects/Zone-C
./install.sh
```

`install.sh` hỏi trước mỗi bước (thêm `--yes` để bỏ hỏi, `--dry-run` để xem trước):

1. Cài gói từ repo Arch: Hyprland và phiên làm việc, âm thanh, mạng, Bluetooth, gõ tiếng Việt (fcitx5 + Unikey), LibreOffice, Flameshot, nén/giải nén, xem ảnh/video/PDF, hỗ trợ ổ NTFS/exFAT, và nhóm lệnh cơ bản. `quickshell`, `matugen`, VS Code, Notion lấy từ AUR nếu repo không có (tự cài `yay` khi cần).
2. Tạo symlink: repo → `~/.config/quickshell/zone-c`, và `dotfiles/` → `~/.config/{hypr,kitty,rofi,matugen,gtk-3.0,gtk-4.0}`, `mimeapps.list`, `code-flags.conf`, `electron-flags.conf`, `~/.zshrc`, `~/.local/bin/{zone-c-wallpaper,zone-c-session}`. Config cũ được chuyển vào `~/.local/state/zone-c/backup-<thời gian>/`.
3. Tạo `~/.config/zone-c/shell.json`, bảng màu mặc định trong `~/.cache/zone-c/`, cấu hình lần đầu cho fcitx5, Flameshot, qt6ct, và chép ảnh nền mặc định vào `~/Pictures/Wallpapers/`.
4. Bật NetworkManager, bluetooth, power-profiles-daemon, đồng bộ giờ, fstrim; hỏi bật SDDM và đổi shell sang zsh.

Shell **chính là** daemon thông báo, nên đừng chạy thêm swaync/dunst/mako: chỉ một chương trình được giữ `org.freedesktop.Notifications`.

Xong thì đăng xuất (hoặc khởi động lại) và chọn phiên **Hyprland**. Lần đầu vào sẽ dùng ảnh nền mặc định của Zone-C. Bỏ ảnh của bạn vào `~/Pictures/Wallpapers` rồi bấm `SUPER+SHIFT+W` để đổi: bar, popup, viền cửa sổ, kitty, rofi, swaync đổi màu theo ảnh (matugen).

### Ba việc phải tự làm sau khi cài

**Gõ tiếng Việt:** bộ gõ mặc định là Unikey, chuyển bằng `CTRL+Space`. Nếu bảng chọn bộ gõ trống thì mở `fcitx5-configtool` và thêm Unikey.

**Cho keyring tự mở khoá** (không làm thì Chrome, VS Code, Notion hỏi mật khẩu keyring mỗi lần đăng nhập). Installer không tự sửa vì đây là file xác thực của hệ thống. Thêm 2 dòng vào cuối `/etc/pam.d/sddm`:

```bash
sudo cp /etc/pam.d/sddm /etc/pam.d/sddm.backup
sudo tee -a /etc/pam.d/sddm >/dev/null <<'EOF'
auth     optional  pam_gnome_keyring.so
session  optional  pam_gnome_keyring.so auto_start
EOF
```

Mật khẩu keyring phải trùng mật khẩu đăng nhập thì mới tự mở được.

**Cho gammastep xin được vị trí** (không làm thì lọc ánh sáng xanh im lặng không chạy). `/etc/geoclue/geoclue.conf` của Arch chỉ cho phép sẵn vài ứng dụng GNOME và Firefox:

```bash
sudo tee -a /etc/geoclue/geoclue.conf >/dev/null <<'EOF'

[gammastep]
allowed=true
system=false
users=
EOF
```

Hoặc bỏ qua định vị và ghi thẳng toạ độ: đổi `exec-once = sleep 1 && gammastep` trong `dotfiles/hypr/conf/autostart.conf` thành `gammastep -l 21.03:105.85`.

Vì là symlink, `git pull` trong repo là cập nhật luôn cả shell lẫn dotfiles. Chỉnh riêng cho từng máy (màn hình, layout bàn phím) đặt trong `~/.config/hypr/local.conf`, file này không vào git.

## Phím tắt chính

| Phím | Việc |
|---|---|
| nhấn thả `SUPER` | tìm ứng dụng (launcher của shell) |
| `SUPER+T` / `W` / `C` / `E` | terminal / trình duyệt / VS Code / Thunar |
| `SUPER+Q` / `F` / `ALT+F` / `ALT+Space` / `P` | đóng / toàn màn hình / phóng to / nổi / ghim cửa sổ |
| `SUPER+1…0`, `SUPER+ALT+1…0` | chuyển / chuyển cửa sổ sang workspace |
| `CTRL+SUPER+←/→`, `SUPER+Page Up/Down` | workspace trước / sau |
| `SUPER+S` / `M` / `D` / `R`, `CTRL+SHIFT+Esc` | workspace đặc biệt: chung / nhạc / chat / ghi chú (Notion) / btop |
| `SUPER+ALT+mũi tên`, `SUPER+-/=` | đổi kích thước cửa sổ |
| `ALT+Tab`, `SUPER+,` / `SUPER+U` | chuyển cửa sổ, gộp nhóm / tách khỏi nhóm |
| `SUPER+K` / `ALT+M` / `A` / `B` | popup lịch / nhạc / âm lượng / pin |
| `SUPER+SHIFT+N` / `SUPER+SHIFT+B` | popup mạng tab Wi-Fi / Bluetooth |
| `SUPER+N` / `SUPER+SHIFT+D` / `CTRL+ALT+C` | trung tâm thông báo / không làm phiền / xoá hết thông báo |
| `SUPER+V` / `SUPER+.` / `SUPER+SHIFT+W` | clipboard / emoji / chọn hình nền |
| `SUPER+L` / `SUPER+SHIFT+L` / `CTRL+ALT+Del` | khoá màn hình / ngủ / menu tắt máy |
| `Print` / `SUPER+SHIFT+S` / `SUPER+SHIFT+ALT+S` | Flameshot: chụp cả màn hình / chọn vùng và vẽ chú thích / chọn vùng sau 3 giây |
| `SUPER+SHIFT+C` | lấy màu |
| `SUPER+ALT+R` / `CTRL+ALT+R` | quay vùng / cả màn hình (bấm lại để dừng) |
| `CTRL+SUPER+ALT+R` | khởi động lại shell |

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
- `enabled`: feature không có widget trên bar nhưng vẫn cần nạp. Mặc định `["clipboard", "osd"]` — clipboard là popup mở bằng phím tắt, osd là overlay tự hiện.
- `features.launcher`: `maxResults`, `placeholder`, và `terminal` (lệnh chạy cho ứng dụng khai báo `Terminal=true`).
- `features.clipboard`: `maxEntries`, `placeholder`.
- `features.notifications`: `maxToasts`, `timeoutMs`, `keepCritical` (toast mức critical ở lại cho tới khi bấm).
- `features.osd`: `timeoutMs`, `marginBottom`.
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
