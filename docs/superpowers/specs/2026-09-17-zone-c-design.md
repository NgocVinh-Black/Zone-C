# Zone-C — Thiết kế tổng thể

- Ngày: 2026-09-17
- Trạng thái: đã duyệt; giai đoạn 1–2 đã triển khai

## 1. Mục tiêu

Zone-C là một desktop shell cá nhân viết bằng Quickshell cho Hyprland, xây từ đầu:

- **Cấu trúc code**: Core + Features + Slots. Mỗi tính năng là một thư mục khép kín; phần lõi chỉ cung cấp khung và không biết tính năng cụ thể nào. Sửa, thêm hoặc bỏ một tính năng chỉ chạm vào một thư mục.
- **Giao diện**: gần giống Serpantinum v1 (imperative-dots), gồm thanh bar là các khối nổi tách rời và popup mọc ra từ cạnh bar với hiệu ứng morph.

### Phạm vi môi trường

| Hạng mục | Chọn |
|---|---|
| Hệ điều hành | Arch Linux |
| Compositor | Chỉ Hyprland (config dạng Lua) |
| Toolkit | Quickshell bản chính thức trong repo Arch (`quickshell`), Qt 6 |
| Ngôn ngữ | QML + JavaScript. Không C++, không cần build |
| Script ngoài | Chỉ khi Quickshell không có API tương ứng, và chỉ được gọi từ file `*Service.qml` |

### Nguyên tắc bản quyền

- Toàn bộ code Zone-C là **code tự viết**.
- Serpantinum v1 không có giấy phép: **không chép code**, chỉ tham khảo giao diện (bố cục, màu, kích thước, thời gian animation).
- Caelestia (GPL-3.0): chỉ tham khảo ý tưởng, không chép code.

## 2. Kiến trúc

### 2.1 Tổng quan

```
shell.qml
   │
   ▼
core/  ── khung: config, theme, ui, bar (slot), popup (host), feature loader, services dùng chung
   ▲
   │  core nạp feature theo tên trong config, qua hợp đồng feature.qml
   │
features/<tên>/  ── mỗi tính năng khép kín: service + widget bar + popup + schema
```

Hai chiều phụ thuộc được phép:
- `features/X` → `core/*`
- `core/feature/` nạp `features/X/feature.qml` **theo đường dẫn quy ước**, không import tĩnh.

Không được phép:
- `core/*` import `features/*`
- `features/X` import `features/Y`

### 2.2 Cây thư mục

```
Zone-C/
├── shell.qml                    # Điểm vào: nạp Config, FeatureLoader, Bar, PopupHost
├── core/
│   ├── config/
│   │   ├── Config.qml           # singleton: đọc/theo dõi/ghi ~/.config/zone-c/shell.json
│   │   ├── ConfigValidator.js   # hàm thuần: gộp mặc định + kiểm tra kiểu (có test)
│   │   └── CoreSchema.js        # schema phần chung: general, theme, bar layout
│   ├── theme/
│   │   ├── Tokens.qml           # singleton: khoảng cách, bo góc, font, độ trong, animation
│   │   └── Colours.qml          # singleton: bảng màu (matugen → fallback Catppuccin Mocha)
│   ├── state/
│   │   ├── ShellState.qml       # singleton: popup nào đang mở, trên màn hình nào
│   │   ├── Scale.qml            # singleton: hệ số co giãn
│   │   ├── ScaleMath.js         # hàm thuần (có test)
│   │   └── Paths.qml            # singleton: đường dẫn config/cache/state
│   ├── services/                # CHỈ service dùng bởi nhiều feature
│   │   └── Hypr.qml             # workspaces, cửa sổ focus, layout bàn phím, dispatch
│   ├── ui/                      # component giao diện thuần, không biết hệ thống
│   │   ├── Block.qml            # khối nổi kiểu v1
│   │   ├── Pill.qml             # pill trạng thái kiểu v1 (icon + chữ, nền gradient khi active)
│   │   ├── StyledText.qml
│   │   ├── Icon.qml
│   │   ├── IconButton.qml
│   │   ├── HoverArea.qml
│   │   ├── Anim.qml
│   │   └── ColorAnim.qml
│   ├── feature/
│   │   ├── Feature.qml          # kiểu dữ liệu của hợp đồng feature
│   │   ├── FeatureLoader.qml    # singleton: nạp feature bật trong config
│   │   └── FeatureContract.js   # hàm thuần: kiểm tra hợp đồng (có test)
│   ├── bar/
│   │   ├── Bar.qml              # PanelWindow + 3 vùng trái/giữa/phải
│   │   ├── BarZone.qml          # một vùng: danh sách nhóm
│   │   ├── BarGroup.qml         # một Block chứa 1..n widget của các feature
│   │   └── BarWidget.qml        # kiểu gốc cho widget bar của feature
│   └── popup/
│       ├── PopupHost.qml        # một cửa sổ mỗi màn hình, morph giữa các popup
│       └── PopupLayout.js       # hàm thuần tính toạ độ (có test)
├── features/
│   ├── workspaces/  feature.qml  WorkspacesWidget.qml  WorkspaceButton.qml  schema.js
│   ├── media/       feature.qml  MediaService.qml  MediaWidget.qml  (+ MusicPopup.qml)
│   ├── clock/       feature.qml  ClockService.qml  ClockWidget.qml  schema.js  (+ CalendarPopup.qml)
│   ├── weather/     feature.qml  WeatherService.qml  WeatherWidget.qml  WeatherLogic.js  schema.js
│   ├── tray/        feature.qml  TrayWidget.qml
│   ├── keyboard/    feature.qml  KeyboardWidget.qml  KeyboardLogic.js
│   ├── network/     feature.qml  NetworkService.qml  NetworkWidget.qml  NetworkLogic.js  (+ NetworkPopup.qml)
│   ├── bluetooth/   feature.qml  BluetoothService.qml  BluetoothWidget.qml  BluetoothLogic.js
│   ├── volume/      feature.qml  VolumeService.qml  VolumeWidget.qml  VolumeLogic.js  (+ VolumePopup.qml, VolumeOsd.qml)
│   ├── battery/     feature.qml  BatteryService.qml  BatteryWidget.qml  BatteryLogic.js  (+ BatteryPopup.qml)
│   ├── launcher/    …
│   ├── clipboard/   …
│   ├── notifications/ …
│   ├── lock/        …
│   ├── wallpaper/   …
│   └── settings/    …
├── tools/
│   └── check.sh                 # kiểm tra quy tắc kiến trúc + qmllint + test
├── config/
│   └── shell.example.json       # config mẫu
└── tests/js/                    # node --test
    ├── load.mjs                 # nạp file .pragma library vào Node
    ├── configvalidator.test.mjs
    ├── coreschema.test.mjs
    ├── scalemath.test.mjs
    ├── popuplayout.test.mjs
    ├── featurecontract.test.mjs
    ├── featurelogic.test.mjs    # các *Logic.js của feature
    └── features.test.mjs        # mọi features/*/feature.qml hợp lệ
```

Quickshell tự phân giải module `qs.*` theo thư mục, không cần `qmldir`; singleton khai báo bằng `pragma Singleton`. Import dùng tên gốc Quickshell: `import qs.core.ui`, `import qs.core.theme`, `import qs.features.battery` (chỉ trong chính thư mục battery).

`(+ …)` là file của giai đoạn sau. Logic thuần của feature nằm trong `*Logic.js` để test được.

Popup, service và widget của feature chỉ được tạo khi cần: service là singleton nên chỉ khởi tạo khi có người dùng, popup nạp bằng `Loader` khi mở.

### 2.3 Hợp đồng feature

Mỗi feature có file `feature.qml` duy nhất khai báo những gì nó cung cấp:

```qml
import qs.core.feature

Feature {
    name: "battery"                       // trùng tên thư mục
    barWidget: Qt.resolvedUrl("BatteryWidget.qml")      // tuỳ chọn
    popup: ({                             // tuỳ chọn
        component: Qt.resolvedUrl("BatteryPopup.qml"),
        anchor: "top-right",              // top-left | top-right | top-center | center
        width: 801,
        height: 760
    })
}
```

Config riêng của feature nằm trong `schema.js` cạnh nó (`var fields = {...}`), được đọc bằng `Config.feature("<tên>", Schema.fields)` và nằm dưới `features.<tên>` trong `shell.json`. Thuộc tính `overlays` (cửa sổ luôn có như OSD, thông báo) sẽ được thêm vào hợp đồng ở giai đoạn 4.

`FeatureContract.js` kiểm tra lúc chạy: `name` khớp thư mục, `anchor` hợp lệ, `width`/`height` > 0. `tests/js/features.test.mjs` kiểm tra thêm rằng file khai báo tồn tại. Hợp đồng sai: cảnh báo và bỏ qua feature đó, shell vẫn chạy.

Widget bar kế thừa `core/bar/BarWidget.qml`, nhận `featureName`, `screen`, `barWindow`, `indexInGroup`, có `compact` (màn hình rộng dưới 1920) và `openPopup()`. Widget đặt `shown` (không đặt `visible`) để báo có dữ liệu hay không.

### 2.4 Slot trên bar

Config quyết định feature nào bật và nằm ở đâu. Mỗi phần tử là một **nhóm**; mỗi nhóm được vẽ trong **một** `Block`:

```json
{
  "bar": {
    "left":   [["workspaces"], ["media"]],
    "center": [["clock", "weather"]],
    "right":  [["tray"], ["keyboard", "network", "bluetooth", "volume", "battery"]]
  },
  "features": {
    "workspaces": { "count": 8 },
    "weather": { "unit": "metric" }
  }
}
```

- Một feature được nạp khi xuất hiện trong `bar` hoặc trong `enabled` (cho feature không có widget bar như `notifications`, `lock`).
- Feature trong config mà không có thư mục: cảnh báo, bỏ qua.
- Widget đặt `shown: false` khi dữ liệu không có; `BarGroup` đếm số widget `shown` và ẩn khi bằng 0.

### 2.5 Quy tắc bắt buộc

`tools/check.sh` kiểm tra tự động và trả mã lỗi khác 0 khi vi phạm.

| # | Quy tắc | Cách kiểm tra |
|---|---|---|
| R1 | Chỉ file `*Service.qml` và `core/services/` được dùng `Process`, `execDetached`, `hyprctl` | grep |
| R2 | Ngoài `core/theme/` không có màu dạng `"#rrggbb"` hoặc `Qt.rgba(` với số cứng | grep |
| R3 | Ngoài `core/config/` không đọc config thô (`JSON.parse`, `FileView` trỏ vào `shell.json`) | grep |
| R4 | `core/` không import `qs.features`; `features/X` không import `qs.features.Y` | grep |
| R5 | File QML ngoài `tests/` không quá 400 dòng | wc |
| R6 | Mỗi `features/*/` có `feature.qml`, tên khớp thư mục, file khai báo tồn tại; toàn bộ unit test qua | `tests/js/features.test.mjs` + `node --test` |
| R7 | `qmllint` | chỉ báo, không chặn (qmllint không phải lúc nào cũng hiểu kiểu của Quickshell) |

## 3. Core

### 3.1 Config

- File người dùng: `~/.config/zone-c/shell.json`. Không bắt buộc tồn tại.
- Schema dạng `{ key: { type, default, min?, max?, enum? } }`. `CoreSchema.js` cho phần chung (`general`, `theme`, `bar`, `enabled`); mỗi feature có `schema.js` riêng gắn dưới `features.<name>`.
- `ConfigValidator.js` gộp giá trị người dùng với mặc định. Sai kiểu hoặc ngoài giới hạn: cảnh báo, dùng mặc định. Key lạ: cảnh báo, bỏ qua.
- Truy cập: `Config.general.uiScale`, `Config.bar.left`, `Config.feature("workspaces").count`.
- Theo dõi file bằng `FileView`; sửa file là áp dụng ngay.
- Giá trị `default: null` nghĩa là tuỳ chọn: không đặt thì là `null`, đặt thì vẫn được kiểm tra.
- Ghi file (cho app settings, giai đoạn 5): file tạm rồi đổi tên (atomic), debounce 300ms. Không ghi đè khi file người dùng đang hỏng.

### 3.2 Tokens (giá trị từ v1)

| Token | Giá trị | Nguồn v1 |
|---|---|---|
| `bar.height` | 48 | `barHeight: s(48)` |
| `bar.marginTop` / `bar.marginSide` | 8 / 4 | margins của TopBar |
| `block.radius` | 14 | các khối bar |
| `block.opacity` | 0.75 | `Qt.rgba(base, 0.75)` |
| `block.borderWidth` / `block.borderAlpha` | 1 / 0.08 | viền `text` |
| `block.gap` | 4 | khoảng cách giữa khối |
| `block.paddingX` / `block.itemGap` | 10 / 8 | khối status `+ s(20)`, pill cách nhau 8 |
| `pill.height` / `pill.radius` / `pill.paddingX` | 34 / 10 / 12 | pill bên phải |
| `pill.alpha` / `pill.hoverAlpha` / `pill.hoverScale` | 0.4 / 0.6 / 1.05 | nền `surface0` / hover `surface1` |
| `workspace.size` / `workspace.radius` / `workspace.spacing` | 32 / 10 / 6 | nút workspace |
| `font.text` | "JetBrains Mono" | |
| `font.icon` | "Iosevka Nerd Font" | |
| `font.size.small` / `body` / `clock` / `icon` | 11 / 14 / 16 / 16 | |
| `anim.morph` / `anim.switch` / `anim.exit` | 230 / 210 / 160 ms | `Main.qml` |
| `anim.color` | 250 ms | |
| `popup.marginTop` / `popup.radius` / `popup.padding` | 60 / 14 / 12 | `getPopupLayout` |

Mọi kích thước đi qua `Scale.s(value)`.

### 3.3 Colours

- Tên màu theo Catppuccin: `base, mantle, crust, text, subtext0/1, surface0–2, overlay0–2, blue, sapphire, peach, green, red, mauve, pink, yellow, maroon, teal`.
- Mặc định: Catppuccin Mocha.
- Khi `Config.theme.matugen = true`: đọc `~/.cache/zone-c/colors.json`; key thiếu dùng mặc định.

### 3.4 Scale

Công thức giống v1, chuẩn 1920×1080:
- `r = min(w/1920, h/1080)`
- `r ≤ 1`: `base = max(0.35, r^0.85)`; `r > 1`: `base = r^0.5`
- `scale = base × Config.general.uiScale`
- `s(v) = round(v × scale)`

### 3.5 Service dùng chung trong core

Chỉ đưa service vào `core/services/` khi **từ hai feature trở lên** cần. Ban đầu chỉ có:

| Service | Nguồn | Thuộc tính | Hành động | Dùng bởi |
|---|---|---|---|---|
| Hypr | `Quickshell.Hyprland` | `workspaces`, `activeWorkspaceId`, `keyboardLayout`, `isOccupied(id)` | `focusWorkspace(id)`, `switchLayout()` | workspaces, keyboard, lock |

`ShellState` (`core/state/`): `activePopup`, `activeScreen`, `toggle(name, screen)`, `close()`.

### 3.6 Bar

- `Bar.qml`: `PanelWindow` trong suốt mỗi màn hình, cao 48, cách trên 8, hai bên 4, `exclusiveZone` bằng chiều cao.
- `BarZone` trái căn trái, phải căn phải; vùng giữa luôn căn giữa màn hình, và bị đẩy sang khi chạm vùng trái.
- `BarGroup` = một `Block`, các widget xếp ngang cách nhau `Tokens.block.gap`.

### 3.7 Popup host

- `PopupHost`: một `PanelWindow` layer overlay mỗi màn hình.
- Khi `ShellState.activePopup` đổi, host lấy khai báo `popup` từ feature tương ứng, dùng `PopupLayout.js` tính `x, y` theo `anchor`, kích thước màn hình, `Scale` và `Tokens.popup.marginTop`.
- Mở: nền morph từ vị trí widget trên bar sang kích thước đích trong 230ms (`OutCubic`), nội dung fade in. Chuyển popup: 210ms. Đóng: 160ms.
- Bấm ra ngoài hoặc Esc thì đóng. Nội dung nạp bằng `Loader`, huỷ sau khi đóng.

## 4. Features

### 4.1 Giai đoạn 2: bar kiểu v1

| Feature | Service | Widget bar | Popup (giai đoạn sau) |
|---|---|---|---|
| workspaces | `core/services/Hypr` | Nút số 1…`count` (mặc định 8). Đang chọn: nền `blue`, chữ `crust`, đậm nhất. Có cửa sổ: nền `text` α 0.15. Trống: chữ `overlay0`. Hover: nền `text` α 0.1. Bấm: `Hypr.focusWorkspace` | — |
| media | `MediaService` (`Services.Mpris`): `title`, `artist`, `artUrl`, `playing`, `available`; `playPause()`, `next()`, `previous()` | Ảnh bìa nhỏ, tên bài, nút phát/dừng. Ẩn khi không có trình phát | music (top-left, 700×650) |
| clock | `ClockService`: một `Timer` 1s; `timeText` (`HH:mm:ss`), `dateText` | Giờ màu `blue` cỡ 16 đậm, ngày cỡ 11 `subtext0` bên dưới | calendar (top-center, 1450×750) |
| weather | `WeatherService` (Open-Meteo, không cần key): `icon`, `temperature`, `available`; `refresh()` | Icon + nhiệt độ. Ẩn khi chưa có dữ liệu | — |
| tray | `Services.SystemTray` trực tiếp | Icon tray, chuột trái kích hoạt, chuột phải mở menu | — |
| keyboard | `core/services/Hypr` | Icon + mã layout. Bấm: `Hypr.switchLayout()` | — |
| network | `NetworkService` (`Quickshell.Networking`, fallback `nmcli`): `kind`, `ssid`, `strength`; `toggleWifi()` | Icon + SSID hoặc "Ethernet" | network (top-right, 900×700) |
| bluetooth | `BluetoothService` (`Quickshell.Bluetooth`): `enabled`, `connectedDevice`, `available` | Icon + tên thiết bị. Ẩn khi không có adapter | — |
| volume | `VolumeService` (`Services.Pipewire`): `volume`, `muted`; `setVolume()`, `toggleMute()` | Icon + %. Cuộn để chỉnh | volume (top-right, 450×700) + OSD |
| battery | `BatteryService` (`Services.UPower`): `percent`, `charging`, `available` | Icon + %. Ẩn khi không có pin | battery (top-right, 801×760) |

Nếu API Quickshell khác tên trên phiên bản đang cài, chỉ sửa trong `*Service.qml` của feature đó.

### 4.2 Giai đoạn sau

`launcher` (center, 800×700), `clipboard` (center, 800×700), `notifications` (overlay), `lock`, `wallpaper` (+ matugen), `settings`. Thiết kế giao diện chi tiết của từng popup bổ sung khi tới giai đoạn tương ứng, dựa trên popup v1.

## 5. Luồng dữ liệu

```
shell.json ─► Config ─► FeatureLoader nạp features/<tên>/feature.qml cho mỗi tên trong bar/enabled
                     ─► Bar dựng BarZone → BarGroup → barWidget của từng feature
UPower ─► BatteryService ─► BatteryWidget (bar) + BatteryPopup
Bấm BatteryWidget ─► ShellState.toggle("battery", screen) ─► PopupHost ─► feature("battery").popup ─► morph
Hyprland IPC ─► core/services/Hypr ─► WorkspacesWidget, KeyboardWidget
```

## 6. Xử lý lỗi

| Tình huống | Hành vi |
|---|---|
| `shell.json` hỏng JSON | Cảnh báo, dùng toàn bộ mặc định, không ghi đè file |
| Key sai kiểu/ngoài giới hạn | Cảnh báo, dùng mặc định cho key đó |
| Tên feature trong config không tồn tại | Cảnh báo, bỏ qua |
| `feature.qml` sai hợp đồng hoặc lỗi nạp | Cảnh báo, bỏ qua feature đó, shell vẫn chạy |
| Popup lỗi nạp | Cảnh báo, đóng popup |
| Thiết bị không có (pin, bluetooth) | `available: false`, widget ẩn |
| Thời tiết lỗi mạng | Giữ dữ liệu cũ, thử lại sau 10 phút |
| Lệnh ngoài thất bại | Service cảnh báo, giữ trạng thái cũ |

## 7. Kiểm thử

- **Hàm thuần** (`ConfigValidator.js`, `CoreSchema.js`, `ScaleMath.js`, `PopupLayout.js`, `FeatureContract.js`, các `*Logic.js` của feature): test bằng `node --test` trong `tests/js/`. File JS dùng `.pragma library` nên chạy được cả trong QML lẫn Node.
- **Hợp đồng feature**: `tests/js/features.test.mjs` kiểm tra mọi `features/*/feature.qml`.
- **Quy tắc kiến trúc**: `tools/check.sh` chạy R1–R7.
- **Chạy thật**: `qs -p shell.qml` trong phiên Hyprland; Quickshell tự reload khi sửa file.
- Mỗi giai đoạn chỉ coi là xong khi `check.sh` qua và đã chạy thật trên Hyprland.

## 8. Lộ trình

| Giai đoạn | Nội dung | Kết quả |
|---|---|---|
| 1. Core | config + validator, theme, state, `Hypr`, ui, feature loader + hợp đồng, bar khung (slot rỗng), popup host (chưa có popup), `check.sh`, tests | Shell khởi động với bar rỗng, test qua |
| 2. Bar | features: workspaces, media, clock, weather, tray, keyboard, network, bluetooth, volume, battery (chỉ widget + service) | Bar dùng được hằng ngày |
| 3. Popup phải + music | popup của battery, network, volume, media, clock | |
| 4. Popup giữa + hệ thống | launcher, clipboard, notifications, OSD volume | |
| 5. Hoàn thiện | lock, wallpaper + matugen, settings | |

Mỗi giai đoạn có kế hoạch triển khai riêng.

## 9. Ngoài phạm vi

- Compositor khác Hyprland; bar dọc.
- Widget Movies, updater, focustime, stewart, guide của v1.
- Installer tự động, gói AUR, Nix. Giai đoạn đầu chạy trực tiếp bằng `qs -p`.
- Telemetry.
