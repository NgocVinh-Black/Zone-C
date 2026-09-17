# Zone-C — Thiết kế tổng thể

- Ngày: 2026-09-17
- Trạng thái: đã duyệt hướng, chờ duyệt tài liệu

## 1. Mục tiêu

Zone-C là một desktop shell viết bằng Quickshell cho Hyprland, xây từ đầu:

- **Cấu trúc code** học theo Caelestia: chia tầng rõ ràng, mỗi file một việc, sửa chỗ này không làm hỏng chỗ khác.
- **Giao diện** gần giống Serpantinum v1 (imperative-dots): thanh bar gồm các khối nổi tách rời, popup mọc ra từ cạnh bar với hiệu ứng morph.

### Phạm vi môi trường

| Hạng mục | Chọn |
|---|---|
| Hệ điều hành | Arch Linux |
| Compositor | Chỉ Hyprland (config dạng Lua) |
| Toolkit | Quickshell bản chính thức trong repo Arch (`quickshell`), Qt 6 |
| Ngôn ngữ | QML + JavaScript. Không C++, không cần build |
| Script ngoài | Chỉ khi Quickshell không có API tương ứng, và chỉ được gọi từ `services/` |

### Nguyên tắc bản quyền

- Toàn bộ code Zone-C là **code tự viết**.
- Serpantinum v1 không có giấy phép: **không chép code**, chỉ tham khảo giao diện (bố cục, màu, kích thước, thời gian animation).
- Caelestia (GPL-3.0): chỉ tham khảo **ý tưởng kiến trúc**, không chép code.

## 2. Kiến trúc

### 2.1 Các tầng

Phụ thuộc chỉ đi **một chiều từ trên xuống**. Tầng dưới không bao giờ biết tầng trên.

```
modules/      Màn hình: bar, popups, notifications…      ─┐
components/   Khối giao diện dùng chung                   │ chỉ phụ thuộc xuống dưới
services/     Dữ liệu hệ thống + trạng thái shell         │
config/ theme/ utils/   Nền tảng                          ─┘
```

| Tầng | Được dùng | Không được dùng |
|---|---|---|
| `config/`, `theme/`, `utils/` | Quickshell, Qt | services, components, modules |
| `services/` | config, utils, `Process`, API Quickshell | components, modules, theme |
| `components/` | theme, config, utils | services, modules, `Process` |
| `modules/` | components, services, theme, config, utils | module khác, `Process`, `execDetached` |

### 2.2 Cây thư mục

```
Zone-C/
├── shell.qml                 # Điểm vào. Chỉ khai báo các module cấp cao
├── config/
│   ├── qmldir
│   ├── Config.qml            # singleton: đọc, kiểm tra, ghi ~/.config/zone-c/shell.json
│   ├── ConfigValidator.js    # hàm thuần: gộp mặc định + kiểm tra kiểu (có test)
│   └── schema/
│       ├── GeneralSchema.js
│       ├── BarSchema.js
│       └── PopupSchema.js    # mỗi phần config một file: key, kiểu, mặc định
├── theme/
│   ├── qmldir
│   ├── Tokens.qml            # singleton: khoảng cách, bo góc, font, độ trong, animation
│   └── Colours.qml           # singleton: bảng màu (matugen → fallback Catppuccin Mocha)
├── utils/
│   ├── qmldir
│   ├── Scale.qml             # singleton: hệ số co giãn theo màn hình
│   ├── ScaleMath.js          # hàm thuần (có test)
│   └── Paths.qml             # đường dẫn config/cache/state
├── services/
│   ├── qmldir
│   ├── Hypr.qml              # workspaces, cửa sổ focus, layout bàn phím, dispatch
│   ├── Audio.qml             # Pipewire: âm lượng, mute, thiết bị
│   ├── Battery.qml           # UPower: %, đang sạc, có pin không
│   ├── Network.qml           # wifi/ethernet: trạng thái, SSID, cường độ
│   ├── Bluetooth.qml         # bật/tắt, thiết bị đang kết nối
│   ├── Media.qml             # MPRIS: bài hát, nghệ sĩ, ảnh bìa, điều khiển
│   ├── Tray.qml              # SystemTray
│   ├── Weather.qml           # thời tiết + cache
│   ├── Time.qml              # đồng hồ dùng chung (một Timer cho cả shell)
│   └── ShellState.qml        # popup nào đang mở trên màn hình nào
├── components/
│   ├── qmldir
│   ├── Block.qml             # khối nổi kiểu v1
│   ├── StyledText.qml
│   ├── Icon.qml              # glyph Nerd Font
│   ├── IconButton.qml
│   ├── HoverArea.qml
│   ├── Slider.qml
│   └── Anim.qml              # NumberAnimation mặc định theo Tokens
├── modules/
│   ├── bar/
│   │   ├── Bar.qml           # PanelWindow + 3 vùng trái/giữa/phải
│   │   └── components/
│   │       ├── Workspaces.qml
│   │       ├── WorkspaceButton.qml
│   │       ├── MediaBlock.qml
│   │       ├── ClockBlock.qml
│   │       ├── WeatherInline.qml
│   │       ├── TrayBlock.qml
│   │       └── status/
│   │           ├── StatusBlock.qml
│   │           ├── KeyboardPill.qml
│   │           ├── NetworkPill.qml
│   │           ├── BluetoothPill.qml
│   │           ├── VolumePill.qml
│   │           └── BatteryPill.qml
│   ├── popups/
│   │   ├── PopupHost.qml     # một cửa sổ, morph giữa các popup
│   │   ├── PopupRegistry.qml # bảng vị trí/kích thước + component
│   │   ├── PopupLayout.js    # hàm thuần tính toạ độ (có test)
│   │   ├── battery/  network/  volume/  music/  calendar/
│   │   └── launcher/  clipboard/
│   ├── notifications/
│   ├── osd/
│   ├── lock/
│   ├── wallpaper/
│   └── settings/
├── tools/
│   └── check.sh              # kiểm tra quy tắc kiến trúc + qmllint
└── tests/
    ├── tst_configvalidator.qml
    ├── tst_scalemath.qml
    └── tst_popuplayout.qml
```

Import dùng tên gốc của Quickshell: `import qs.services`, `import qs.components`, `import qs.theme`, `import qs.config`, `import qs.utils`.

### 2.3 Quy tắc bắt buộc

`tools/check.sh` kiểm tra tự động và trả mã lỗi khác 0 khi vi phạm.

| # | Quy tắc | Cách kiểm tra |
|---|---|---|
| R1 | `components/` và `modules/` không dùng `Process`, `execDetached`, `hyprctl` | grep |
| R2 | `components/` và `modules/` không có màu dạng `"#rrggbb"` / `Qt.rgba(` số cứng | grep |
| R3 | Không đọc config thô (`rawSettings`, `JSON.parse` ngoài `config/`) | grep |
| R4 | File trong `modules/X/` không import `modules/Y/` | grep đường dẫn import |
| R5 | File QML trong `components/` và `modules/` không quá 400 dòng | wc |
| R6 | `qmllint` không báo lỗi | qmllint |

## 3. Các thành phần nền

### 3.1 Config

- File người dùng: `~/.config/zone-c/shell.json`. Không bắt buộc tồn tại, thiếu key nào thì dùng mặc định.
- Mỗi schema khai báo `{ key: { type, default, min?, max?, enum? } }`.
- `ConfigValidator.js` gộp giá trị người dùng với mặc định. Key sai kiểu hoặc ngoài giới hạn: ghi cảnh báo, dùng mặc định. Key lạ: ghi cảnh báo, bỏ qua.
- `Config.qml` expose đối tượng đã kiểm tra: `Config.bar.opacity`, `Config.bar.workspaceCount`…
- Theo dõi file bằng `FileView`, sửa file là áp dụng ngay.
- Ghi file: ghi vào file tạm rồi đổi tên (atomic), có debounce 300ms.

### 3.2 Tokens (giá trị từ v1)

| Token | Giá trị | Nguồn v1 |
|---|---|---|
| `bar.height` | 48 | `barHeight: s(48)` |
| `bar.marginTop` / `bar.marginSide` | 8 / 4 | margins của TopBar |
| `block.radius` | 14 | các khối bar |
| `block.opacity` | 0.75 | `Qt.rgba(base, 0.75)` |
| `block.borderWidth` / `block.borderAlpha` | 1 / 0.08 | viền `text` alpha 0.05–0.08 |
| `block.gap` | 4 | khoảng cách giữa khối |
| `workspace.size` / `workspace.radius` | 32 / 10 | nút workspace |
| `font.text` | "JetBrains Mono" | |
| `font.icon` | "Iosevka Nerd Font" | |
| `font.size.small/body/clock` | 11 / 14 / 16 | ngày / workspace / giờ |
| `anim.morph` / `anim.switch` / `anim.exit` | 230 / 210 / 160 ms | `Main.qml` |
| `anim.color` | 250 ms | |
| `popup.marginTop` / `popup.radius` / `popup.padding` | 60 / 14 / 12 | `getPopupLayout` |

Mọi giá trị kích thước đi qua `Scale.s(value)`.

### 3.3 Colours

- Tên màu theo Catppuccin: `base, mantle, crust, text, subtext0/1, surface0–2, overlay0–2, blue, sapphire, peach, green, red, mauve, pink, yellow, maroon, teal`.
- Mặc định: bảng Catppuccin Mocha (giống `MatugenColors.qml` của v1).
- Khi `Config.theme.matugen = true`: đọc file màu do matugen sinh ra trong `~/.cache/zone-c/colors.json`, key thiếu thì dùng mặc định.

### 3.4 Scale

Công thức giống v1, chuẩn 1920×1080:
- `r = min(w/1920, h/1080)`
- `r ≤ 1`: `base = max(0.35, r^0.85)`; `r > 1`: `base = r^0.5`
- `scale = base × Config.general.uiScale`
- `s(v) = round(v × scale)`

### 3.5 Services

Mỗi service là singleton, chỉ expose **thuộc tính chỉ đọc + hàm hành động**, luôn có `available: bool`.

| Service | Nguồn dữ liệu | Thuộc tính chính | Hành động |
|---|---|---|---|
| Hypr | `Quickshell.Hyprland` | `workspaces`, `activeWorkspaceId`, `focusedTitle`, `keyboardLayout` | `focusWorkspace(id)`, `switchLayout()` |
| Audio | `Quickshell.Services.Pipewire` | `volume` (0–1), `muted` | `setVolume(v)`, `toggleMute()` |
| Battery | `Quickshell.Services.UPower` | `percent`, `charging`, `available` | — |
| Network | `Quickshell.Networking`; fallback `nmcli` | `kind` (wifi/ethernet/none), `ssid`, `strength` | `toggleWifi()` |
| Bluetooth | `Quickshell.Bluetooth` | `enabled`, `connectedDevice` | `toggle()` |
| Media | `Quickshell.Services.Mpris` | `title`, `artist`, `artUrl`, `playing`, `available` | `playPause()`, `next()`, `previous()` |
| Tray | `Quickshell.Services.SystemTray` | `items` | — |
| Weather | HTTP (Open-Meteo, không cần API key) | `icon`, `temperature`, `available` | `refresh()` |
| Time | một `Timer` 1s | `now`, `timeText`, `dateText` | — |
| ShellState | trạng thái nội bộ | `activePopup`, `activeScreen` | `toggle(name, screen)`, `close()` |

Nếu một API Quickshell không có hoặc khác tên trên phiên bản đang cài, chỉ sửa trong service đó. Giao diện không thay đổi.

## 4. Giao diện

### 4.1 Thanh bar

Bar là `PanelWindow` trong suốt, cao 48, cách trên 8, cách hai bên 4. Bên trong là các `Block` riêng biệt:

| Vùng | Khối | Nội dung |
|---|---|---|
| Trái | Workspaces | Nút số 1…N (`Config.bar.workspaceCount`, mặc định 8). Đang chọn: nền `blue`, chữ `crust`, đậm nhất. Có cửa sổ: nền `text` alpha 0.15, chữ `text`. Trống: chữ `overlay0`. Hover: nền `text` alpha 0.1 |
| Trái | Media | Chỉ hiện khi có trình phát. Ảnh bìa nhỏ, tên bài, nút phát/dừng |
| Giữa | Clock | Giờ `HH:mm:ss` (màu `blue`, cỡ 16, đậm), ngày bên dưới (cỡ 11, `subtext0`), thời tiết bên cạnh. Luôn căn giữa màn hình |
| Phải | Tray | Icon tray |
| Phải | Status | Các pill: bàn phím, mạng, bluetooth, âm lượng, pin. Pin ẩn khi không có pin |

Tương tác:
- Bấm workspace: `Hypr.focusWorkspace`.
- Cuộn trên Status âm lượng: đổi âm lượng.
- Bấm khối: `ShellState.toggle(<popup>)`.

### 4.2 Hệ thống popup

- `PopupHost` là **một** `PanelWindow` layer overlay cho mỗi màn hình.
- `PopupRegistry` khai báo từng popup: `{ name, component, width, height, anchor }`. `anchor` là `top-left`, `top-right`, `top-center` hoặc `center`.
- `PopupLayout.js` tính `x, y` từ `anchor`, kích thước màn hình, `Scale` và `Tokens.popup.marginTop`.
- Mở popup: nền morph từ khối bar sang kích thước đích trong 230ms (`OutCubic`), nội dung fade in.
- Chuyển popup khi đang mở: morph 210ms.
- Đóng: 160ms. Bấm ra ngoài hoặc Esc thì đóng.
- Mỗi popup là component độc lập, chỉ đọc services.

| Popup | Anchor | Kích thước gốc (trước Scale) |
|---|---|---|
| battery | top-right | 801 × 760 |
| network | top-right | 900 × 700 |
| volume | top-right | 450 × 700 |
| music | top-left | 700 × 650 |
| calendar | top-center | 1450 × 750 |
| launcher | center | 800 × 700 |
| clipboard | center | 800 × 700 |

## 5. Luồng dữ liệu

```
Hyprland IPC ─► services/Hypr ─► Hypr.workspaces ─► bar/Workspaces
UPower       ─► services/Battery ─► Battery.percent ─► bar/BatteryPill + popups/battery
Bấm BatteryPill ─► ShellState.toggle("battery") ─► PopupHost ─► PopupRegistry["battery"] ─► morph
shell.json thay đổi ─► Config ─► Tokens/modules cập nhật qua binding
```

## 6. Xử lý lỗi

| Tình huống | Hành vi |
|---|---|
| `shell.json` hỏng JSON | Cảnh báo, dùng toàn bộ mặc định, không ghi đè file người dùng |
| Key sai kiểu/ngoài giới hạn | Cảnh báo, dùng mặc định cho key đó |
| Thiết bị không có (pin, bluetooth) | `available: false`, khối tương ứng ẩn |
| Không có trình phát nhạc | Khối Media ẩn |
| Thời tiết lỗi mạng | Giữ dữ liệu cũ, thử lại sau 10 phút |
| Lệnh ngoài thất bại | Service ghi cảnh báo, giữ trạng thái cũ |

## 7. Kiểm thử

- **Logic thuần** (`ConfigValidator.js`, `ScaleMath.js`, `PopupLayout.js`): test bằng `qmltestrunner` trong `tests/`.
- **Quy tắc kiến trúc**: `tools/check.sh` chạy R1–R6.
- **Chạy thật**: `qs -p shell.qml` trong phiên Hyprland; Quickshell tự reload khi sửa file.
- Mỗi giai đoạn chỉ coi là xong khi `check.sh` và toàn bộ test đều qua, và đã chạy thật trên Hyprland.

## 8. Lộ trình

| Giai đoạn | Nội dung | Kết quả |
|---|---|---|
| 1. Nền | `shell.qml`, config + schema + validator, Tokens, Colours, Scale, services (Hypr, Audio, Battery, Network, Bluetooth, Media, Tray, Weather, Time, ShellState), components, `check.sh`, tests | Shell khởi động, test qua |
| 2. Bar | Toàn bộ mục 4.1 | Bar dùng được hằng ngày |
| 3. Popup phải + music | PopupHost, PopupRegistry, battery, network, volume, music, calendar | |
| 4. Popup giữa + hệ thống | launcher, clipboard, notifications, OSD | |
| 5. Hoàn thiện | lockscreen, wallpaper + matugen, settings | |

Mỗi giai đoạn có kế hoạch triển khai riêng. Tài liệu này là nền cho giai đoạn 1 và 2; thiết kế chi tiết giao diện từng popup (giai đoạn 3–5) sẽ bổ sung khi tới giai đoạn đó.

## 9. Ngoài phạm vi

- Compositor khác Hyprland.
- Widget Movies, updater, focustime, stewart, guide của v1.
- Installer tự động, gói AUR, Nix. Giai đoạn đầu chạy trực tiếp bằng `qs -p`.
- Telemetry.
