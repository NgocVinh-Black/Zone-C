# Zone-C

Shell desktop cá nhân cho **Hyprland**, viết bằng **Quickshell**.

- Kiến trúc: **Core + Features + Slots**. Mỗi tính năng là một thư mục khép kín trong `features/`.
- Giao diện: theo Serpantinum v1, gồm thanh bar là các khối nổi và bảng màu Catppuccin Mocha.

Thiết kế đầy đủ: [docs/superpowers/specs/2026-09-17-zone-c-design.md](docs/superpowers/specs/2026-09-17-zone-c-design.md)

## Trạng thái

| Giai đoạn | Nội dung | Trạng thái |
|---|---|---|
| 1. Core | config, theme, scale, Hypr, ui, feature loader, bar, popup host, check, tests | ✅ |
| 2. Bar | workspaces, media, clock, weather, tray, keyboard, network, bluetooth, volume, battery | ✅ |
| 3. Popup phải + music | battery, network, volume, music, calendar | ⏳ |
| 4. Popup giữa + hệ thống | launcher, clipboard, notifications, OSD | ⏳ |
| 5. Hoàn thiện | lock, wallpaper + matugen, settings | ⏳ |

## Cài đặt trên Arch

```bash
sudo pacman -S quickshell hyprland networkmanager bluez bluez-utils upower \
    pipewire wireplumber ttf-jetbrains-mono ttf-iosevka-nerd nodejs
sudo systemctl enable --now NetworkManager bluetooth upower
```

## Chạy

```bash
qs -p ~/Projects/Zone-C/shell.qml
```

Quickshell tự reload khi bạn sửa file.

Tự khởi động cùng Hyprland (config Lua):

```lua
hl.on("hyprland.start", function()
  hl.exec_cmd("qs -p ~/Projects/Zone-C/shell.qml")
end)
```

## Cấu hình

File tuỳ chọn: `~/.config/zone-c/shell.json`. Thiếu hoặc sai giá trị nào thì dùng mặc định, và cảnh báo được ghi trong log của `qs`. File được theo dõi, nên lưu là áp dụng ngay.

```bash
mkdir -p ~/.config/zone-c
cp config/shell.example.json ~/.config/zone-c/shell.json
```

- `bar.left` / `bar.center` / `bar.right`: danh sách **nhóm**. Mỗi nhóm là một khối nổi, gồm tên các feature.
- `features.<tên>`: cấu hình riêng của từng feature (xem `features/<tên>/schema.js`).
- `theme.matugen: true`: đọc màu từ `~/.cache/zone-c/colors.json`, dạng `{ "base": "#1e1e2e", ... }`.

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
