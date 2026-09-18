# Zone-C — Thiết kế tổng thể

- Ngày: 2026-09-17
- Trạng thái: đã duyệt; giai đoạn 1–3 đã viết xong code (giai đoạn 3 chưa chạy thử trên Hyprland)

## 1. Mục tiêu

Zone-C là một desktop shell cá nhân viết bằng Quickshell cho Hyprland, xây từ đầu:

- **Cấu trúc code**: Core + Features + Slots. Mỗi tính năng là một thư mục khép kín; phần lõi chỉ cung cấp khung và không biết tính năng cụ thể nào. Sửa, thêm hoặc bỏ một tính năng chỉ chạm vào một thư mục.
- **Giao diện**: giống Serpantinum v1 (imperative-dots) theo ảnh chụp ngày 07/04/2026 (commit `7423a29`): thanh bar là các khối nổi tách rời, popup có nền riêng và mọc ra từ góc của chính nó.

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

Một widget được mở popup của feature khác **theo tên** (`openPopup("network", "bt")`). Đây là chuỗi tra cứu lúc chạy, không phải import; nếu feature kia không được nạp thì không có gì xảy ra.

### 2.2 Cây thư mục

```
Zone-C/
├── shell.qml                    # Điểm vào: mỗi màn hình một Bar và một PopupHost
├── core/
│   ├── config/
│   │   ├── Config.qml           # singleton: đọc/theo dõi ~/.config/zone-c/shell.json
│   │   ├── ConfigValidator.js   # hàm thuần: gộp mặc định + kiểm tra kiểu (có test)
│   │   └── CoreSchema.js        # schema phần chung: general, theme, weather, bar, enabled
│   ├── theme/
│   │   ├── Tokens.qml           # singleton: kích thước, bo góc, font, độ trong, animation
│   │   └── Colours.qml          # singleton: bảng màu (matugen → bảng mặc định lấy từ ảnh v1)
│   ├── state/
│   │   ├── ShellState.qml       # singleton: popup nào đang mở, trên màn hình nào, với tham số gì
│   │   ├── Scale.qml            # singleton: hệ số co giãn
│   │   ├── ScaleMath.js         # hàm thuần (có test)
│   │   └── Paths.qml            # singleton: configDir, cacheDir, stateDir (theo XDG)
│   ├── services/                # CHỈ service dùng bởi từ hai feature trở lên
│   │   ├── Hypr.qml             # workspaces, layout bàn phím, dispatch
│   │   ├── Audio.qml            # PipeWire: thiết bị ra/vào, stream, âm lượng
│   │   ├── Bluetooth.qml        # adapter, thiết bị, kết nối
│   │   ├── Weather.qml          # Open-Meteo: hiện tại + dự báo 5 ngày
│   │   └── WeatherLogic.js      # hàm thuần (có test)
│   ├── ui/                      # component giao diện thuần, không biết hệ thống
│   │   ├── Block.qml            # khối nổi kiểu v1
│   │   ├── Pill.qml             # pill trạng thái (icon + chữ, nền gradient khi active)
│   │   ├── FillSlider.qml       # thanh trượt ngang có gradient
│   │   ├── WaveFill.qml         # lớp chất lỏng có sóng (giữ để xác nhận, gauge tròn)
│   │   ├── HoldArea.qml         # nhấn giữ để xác nhận
│   │   ├── Reveal.qml           # giá trị 0→1 có trễ, cho animation xuất hiện lần lượt
│   │   └── StyledText, Icon, IconButton, HoverArea, Anim, ColorAnim
│   ├── feature/
│   │   ├── Feature.qml          # kiểu dữ liệu của hợp đồng feature
│   │   ├── FeatureLoader.qml    # singleton: nạp feature bật trong config
│   │   └── FeatureContract.js   # hàm thuần: kiểm tra hợp đồng (có test)
│   ├── bar/
│   │   ├── Bar.qml              # PanelWindow + 3 vùng trái/giữa/phải
│   │   ├── BarZone.qml          # một vùng: danh sách nhóm, trượt vào lúc khởi động
│   │   ├── BarGroup.qml         # một Block chứa 1..n widget của các feature
│   │   ├── BarWidget.qml        # kiểu gốc cho widget bar của feature
│   │   └── IconBlockWidget.qml  # widget là một khối vuông có icon (tìm kiếm, chuông)
│   └── popup/
│       ├── PopupHost.qml        # một cửa sổ overlay mỗi màn hình
│       ├── PopupBase.qml        # kiểu gốc cho popup: nền bo góc, đốm màu trôi, animation mở
│       └── PopupLayout.js       # hàm thuần tính toạ độ (có test)
├── features/
│   ├── launcher/      feature.qml  LauncherService.qml  LauncherWidget.qml  schema.js
│   ├── notifications/ feature.qml  NotificationsService.qml  NotificationsWidget.qml  schema.js
│   ├── workspaces/    feature.qml  WorkspacesWidget.qml  WorkspaceButton.qml  schema.js
│   ├── media/         feature.qml  MediaService.qml  EqualizerService.qml  MediaLogic.js  MediaWidget.qml
│   │                  MusicPopup.qml  MusicCover.qml  MusicControls.qml  EqualizerPanel.qml  EqSlider.qml  EqLightning.qml
│   ├── clock/         feature.qml  ClockService.qml  ClockWidget.qml  CalendarLogic.js  schema.js
│   │                  CalendarPopup.qml  CalendarGrid.qml  TimeHub.qml  WeatherStats.qml  ScheduleStrip.qml
│   ├── weather/       feature.qml  WeatherWidget.qml
│   ├── tray/          feature.qml  TrayWidget.qml
│   ├── keyboard/      feature.qml  KeyboardWidget.qml  KeyboardLogic.js
│   ├── network/       feature.qml  NetworkService.qml  NetworkLogic.js  NetworkWidget.qml
│   │                  NetworkPopup.qml  RadioCore.qml  OrbitCard.qml  NodeLinks.qml  ModeDock.qml
│   ├── bluetooth/     feature.qml  BluetoothWidget.qml  BluetoothLogic.js
│   ├── volume/        feature.qml  VolumeWidget.qml  VolumeLogic.js  VolumePopup.qml  VolumeHero.qml  AudioNodeCard.qml
│   ├── battery/       feature.qml  BatteryService.qml  BatteryLogic.js  BatteryWidget.qml  schema.js
│   │                  BatteryPopup.qml  BatteryCore.qml  ActionCapsule.qml  ProfileDock.qml
│   └── clipboard/ …  lock/ …  wallpaper/ …  settings/ …   (giai đoạn 4–5)
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
    ├── featurelogic.test.mjs    # các *Logic.js của feature và WeatherLogic.js
    └── features.test.mjs        # mọi features/*/feature.qml hợp lệ
```

Quickshell tự phân giải module `qs.*` theo thư mục, không cần `qmldir`; singleton khai báo bằng `pragma Singleton`. Import dùng tên gốc Quickshell: `import qs.core.ui`, `import qs.core.theme`, `import qs.features.battery` (chỉ trong chính thư mục battery).

Logic thuần của feature nằm trong `*Logic.js` để test được. Service là singleton nên chỉ khởi tạo khi có người dùng; popup nạp bằng `Loader` khi mở và huỷ khi đóng.

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
        width: 480,                       // pixel ở 1920×1080, được scale
        height: 760                       // có thể là binding (calendar: 510 hoặc 750)
    })
}
```

Config riêng của feature nằm trong `schema.js` cạnh nó (`var fields = {...}`), được đọc bằng `Config.feature("<tên>", Schema.fields)` và nằm dưới `features.<tên>` trong `shell.json`. Thuộc tính `overlays` (cửa sổ luôn có như OSD, thông báo) sẽ được thêm vào hợp đồng ở giai đoạn 4.

`FeatureContract.js` kiểm tra lúc chạy: `name` khớp thư mục, `anchor` hợp lệ, `width`/`height` > 0. `tests/js/features.test.mjs` kiểm tra thêm rằng file khai báo tồn tại. Hợp đồng sai: cảnh báo và bỏ qua feature đó, shell vẫn chạy.

**Widget bar** kế thừa `core/bar/BarWidget.qml`:
- Nhận `featureName`, `screen`, `barWindow`, `indexInGroup`; có `compact` (màn hình rộng dưới 1920).
- `openPopup(name?, arg?)`: mở popup của chính feature, hoặc của feature khác theo tên, kèm tham số (ví dụ tab).
- Đặt `shown` (không đặt `visible`) để báo có dữ liệu hay không.
- Kiểu khối: `blockInteractive` (khối sáng lên và phóng to khi rê chuột), `blockHoverScale`, `blockBorderAlpha`, `blockPadding`. Nhóm lấy padding và viền từ widget đầu tiên.

**Popup** kế thừa `core/popup/PopupBase.qml` (hoặc tự vẽ nền nhưng có cùng hai thuộc tính):
- `screen`: màn hình, do PopupHost đặt.
- `arg`: tham số từ `ShellState.activeArg`, cập nhật khi đang mở.
- PopupBase có sẵn nền bo góc 20, viền `surface0`, hai đốm màu trôi (`blobPrimary`, `blobSecondary`), `intro` (0→1 trong 800ms) và `orbitAngle` (một vòng mỗi 90 giây).

### 2.4 Slot trên bar

Config quyết định feature nào bật và nằm ở đâu. Mỗi phần tử là một **nhóm**; mỗi nhóm được vẽ trong **một** `Block`:

```json
{
  "bar": {
    "left":   [["launcher"], ["notifications"], ["workspaces"], ["media"]],
    "center": [["clock", "weather"]],
    "right":  [["tray"], ["keyboard", "network", "bluetooth", "volume", "battery"]]
  },
  "features": {
    "workspaces": { "count": 8 }
  }
}
```

- Một feature được nạp khi xuất hiện trong `bar` hoặc trong `enabled` (cho feature không có widget bar như `lock`).
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
- Schema dạng `{ key: { type, default, min?, max?, int?, enum?, check? } }`. `CoreSchema.js` cho phần chung (`general`, `theme`, `weather`, `bar`, `enabled`); mỗi feature có `schema.js` riêng gắn dưới `features.<name>`.
- `ConfigValidator.js` gộp giá trị người dùng với mặc định. Sai kiểu hoặc ngoài giới hạn: cảnh báo, dùng mặc định. Key lạ: cảnh báo, bỏ qua.
- Truy cập: `Config.general.uiScale`, `Config.weather.unit`, `Config.bar.left`, `Config.feature("workspaces", Schema.fields).count`.
- Theo dõi file bằng `FileView`; sửa file là áp dụng ngay.
- Giá trị `default: null` nghĩa là tuỳ chọn: không đặt thì là `null`, đặt thì vẫn được kiểm tra.
- Cài đặt thời tiết nằm ở `weather` (phần chung) vì cả widget thời tiết và popup lịch đều dùng.
- Ghi file (cho app settings, giai đoạn 5): file tạm rồi đổi tên (atomic), debounce 300ms. Không ghi đè khi file người dùng đang hỏng.

### 3.2 Tokens (giá trị từ v1)

| Token | Giá trị | Nguồn v1 |
|---|---|---|
| `bar.height` / `bar.marginTop` / `bar.marginSide` | 48 / 8 / 4 | `TopBar.qml` |
| `bar.enterOffset` / `bar.enterDuration` | 30 / 800ms (OutBack 1.1); trễ trái 10, giữa 150, phải 250ms | animation khởi động |
| `block.radius` / `block.opacity` | 14 / 0.75 | các khối bar |
| `block.borderAlpha` / `borderAlphaStatic` / `borderAlphaHover` | 0.05 / 0.08 / 0.15 | viền màu `text` |
| `block.hoverOpacity` | 0.95 | khối hover dùng `surface1` |
| `block.gap` / `block.paddingX` / `block.itemGap` | 4 / 10 / 8 | |
| `iconBlock.size` / `iconBlock.hoverScale` | 48 / 1.05 | nút tìm kiếm, chuông |
| `pill.height` / `pill.radius` / `pill.paddingX` | 34 / 10 / 12 | pill bên phải |
| `pill.alpha` / `pill.hoverAlpha` / `pill.hoverScale` | 0.4 / 0.6 / 1.05 | nền `surface0` / hover `surface1` |
| `workspace.size` / `radius` / `spacing` | 32 / 10 / 6 | nút workspace |
| `workspace.fillAlpha` / `hoverScale` / `enterStagger` | 0.9 / 1.08 / 60ms | |
| `clock.weatherGap` / `clock.hoverScale` | 24 / 1.03 | khối giữa |
| `font.text` / `font.icon` | "JetBrains Mono" / "Iosevka Nerd Font" | |
| `anim.morph` / `anim.morphSwitch` / `anim.exit` | 230 / 210 / 160 ms | `Main.qml` |
| `anim.color` / `anim.orbit` | 250ms / 90s | |
| `popup.marginTop` / `edgeLeft` / `edgeRight` | 70 / 12 / 20 | `WindowRegistry.js` |
| `popup.radius` / `padding` / `introScale` / `introLift` | 20 / 25 / 0.92 / 15 | các popup |

Mọi kích thước đi qua `Scale.s(value)`.

### 3.3 Colours

- Tên màu theo Catppuccin, ánh xạ vai trò matugen giống v1: `base` = surface_container_lowest, `text` = on_surface, `subtext0` = on_surface_variant, `surface0–2` = surface_container…highest, `overlay0–2` = inverse_surface, `blue`/`mauve` = primary, `sapphire` = primary_container, `peach` = tertiary, `green`/`teal` = secondary, `red` = error.
- Mặc định: bảng tối lấy mẫu từ ảnh v1 (nền `#0b0f12`, chữ `#dee3e8`, accent `#8fcef3`, tertiary `#c6c2ea`).
- `white` / `black` cố định cho lớp kính và bóng, không theo theme.
- Khi `Config.theme.matugen = true`: đọc `~/.cache/zone-c/colors.json`; key thiếu dùng mặc định.

### 3.4 Scale

Công thức giống v1, chuẩn 1920×1080:
- `r = min(w/1920, h/1080)`
- `r ≤ 1`: `base = max(0.35, r^0.85)`; `r > 1`: `base = r^0.5`
- `scale = base × Config.general.uiScale`
- `s(v) = round(v × scale)`

Hệ số tính theo màn hình đầu tiên (`Quickshell.screens[0]`) và dùng chung cho mọi màn hình, vì `Tokens` là singleton. Scale riêng từng màn hình nằm ngoài phạm vi hiện tại.

### 3.5 Service dùng chung trong core

Chỉ đưa service vào `core/services/` khi **từ hai feature trở lên** cần.

| Service | Nguồn | Chính | Dùng bởi |
|---|---|---|---|
| Hypr | `Quickshell.Hyprland` | `workspaces`, `activeWorkspaceId`, `keyboardLayout`, `isOccupied(id)`, `focusWorkspace(id)`, `switchLayout()` | workspaces, keyboard |
| Audio | `Quickshell.Services.Pipewire` | `sink`, `source`, `outputs`, `inputs`, `streams`, `volume`, `muted`, `setVolume(node, v)`, `toggleMute(node)`, `setDefault(node)`, `label(node)` | volume, battery |
| Bluetooth | `Quickshell.Bluetooth` | `enabled`, `devices`, `connected`, `nearby`, `toggle()`, `connect(d)`, `disconnect(d)`, `battery(d)`, `setDiscovering(on)` | bluetooth, network |
| Weather | Open-Meteo (không cần key); định vị theo IP qua `ip-api.com` nếu không đặt toạ độ | `icon`, `temperatureText`, `forecast` 5 ngày (max, feelsLike, wind, humidity, pop, desc, 8 mốc giờ 02:00…23:00) | weather, clock |

`ShellState` (`core/state/`): `activePopup`, `activeScreen`, `activeArg`, `toggle(name, screen, arg)`, `close()`. Bấm lại popup đang mở với tham số khác thì chỉ đổi tham số, không đóng.

### 3.6 Bar

- `Bar.qml`: `PanelWindow` trong suốt mỗi màn hình, cao 48, cách trên 8, hai bên 4, `exclusiveZone` bằng chiều cao.
- `BarZone` trái căn trái, phải căn phải; vùng giữa luôn căn giữa màn hình, và bị đẩy sang khi chạm vùng trái/phải (cách 12).
- Lúc khởi động: vùng trái trượt từ trái, vùng giữa rơi xuống, vùng phải trượt từ phải; pill và nút workspace nhô lên lần lượt.
- `BarGroup` = một `Block`, các widget xếp ngang cách nhau 8. Nhóm có widget `blockInteractive` thì khi rê chuột nền thành `surface1` 0.95, viền 0.15 và phóng to.

### 3.7 Popup host

- `PopupHost`: một `PanelWindow` layer overlay mỗi màn hình. Vùng bar được đục khỏi input mask, nên widget bar vẫn bấm được khi popup mở.
- Khi `ShellState.activePopup` đổi, host lấy khai báo `popup` từ feature, dùng `PopupLayout.js` tính `x, y` theo `anchor`, kích thước màn hình, `Scale`, `marginTop` và mép trái/phải.
- Mở: hộp cắt (clip) đặt ở góc trên-trái của vị trí đích và lớn dần từ 1×1 tới kích thước đích trong 230ms (`OutCubic`); nội dung có sẵn kích thước cuối nên không bị co giãn. Chuyển popup: 210ms. Đóng: co về 1×1 và mờ đi trong 160ms.
- Popup tự vẽ nền và animation xuất hiện của mình (phóng từ 0.92, nâng 15px, mờ dần vào).
- Bấm ra ngoài hoặc Esc thì đóng. Nội dung nạp bằng `Loader`, huỷ sau khi đóng.

## 4. Features

### 4.1 Bar

| Feature | Widget bar |
|---|---|
| launcher | Khối vuông 48 với icon kính lúp; hover chuyển `blue`. Bấm chạy `features.launcher.command` (mặc định `rofi -show drun`) cho tới khi có launcher riêng ở giai đoạn 4 |
| notifications | Khối vuông 48 với chuông; hover chuyển `yellow`. Chuột trái / phải chạy `toggleCommand` / `dndCommand` (mặc định swaync) |
| workspaces | Nút 1…`count` (mặc định 8). Đang chọn: nền `mauve`, chữ `crust`, đậm nhất. Có cửa sổ: nền `surface2` 0.9. Hover: nền `overlay0` 0.9, chữ `crust`, phóng 1.08. Trống: chữ `overlay0` |
| media | Ảnh bìa 32, tên bài, dòng thời gian `00:52 / 03:01`, nút trước / phát-dừng / sau. Ẩn khi không có trình phát. Bấm phần tên mở popup nhạc |
| clock | Giờ `hh:mm:ss AP` màu `blue` cỡ 16 đậm, ngày cỡ 11 `subtext0` gõ dần lúc khởi động. Khối giữa hover phóng 1.03. Bấm mở lịch |
| weather | Icon (tint theo loại thời tiết) + nhiệt độ `4.9°C` màu `peach`. Ẩn khi chưa có dữ liệu. Bấm mở lịch |
| tray | Icon tray 18; chuột trái kích hoạt, giữa hành động phụ, phải mở menu |
| keyboard | Pill icon + hai chữ đầu của layout (`EN`). Bấm đổi layout |
| network | Pill wifi (tô `blue` khi wifi bật) + SSID, "Ethernet", "On" hoặc "Off". Bấm mở popup mạng tab Wi-Fi |
| bluetooth | Pill (tô `mauve` khi bật) + tên thiết bị hoặc "Disconnected". Bấm mở popup mạng tab Bluetooth; chuột phải bật/tắt |
| volume | Pill (tô `peach` khi có tiếng) + %. Bấm mở mixer, cuộn chỉnh, chuột phải tắt tiếng |
| battery | Pill + %. Màu theo mức: `blue` ≥70, `yellow` ≥30, `red`; `green` khi sạc. Chỉ tô nền khi sạc hoặc ≤20%, còn lại chỉ tô icon và chữ. Bấm mở popup pin |

### 4.2 Popup giai đoạn 3

| Popup | Vị trí, kích thước | Nội dung |
|---|---|---|
| Nhạc (media) | top-left, 700×620 | Khung gradient xoay 3px quanh nền ảnh bìa làm mờ; đĩa bìa 220 quay khi phát; tên bài chạy chữ khi dài, `BY` nghệ sĩ, thiết bị ra, `VIA` trình phát; thanh tua gradient chảy; nút điều khiển; equalizer 10 băng (-12…+12 dB) với Apply/Saved, 8 preset và tia sét khi áp dụng. EQ áp qua EasyEffects (`easyeffects -l zone-c-eq`), trạng thái lưu ở `stateDir/equalizer.json` |
| Lịch (clock) | top-center, 1450×510 (750 khi có lịch học) | Lịch tháng kính mờ bên trái (đổi tháng, về hôm nay); đồng hồ lớn ở giữa trôi và lắc 3D, quỹ đạo nét đứt với 8 mốc dự báo theo giờ; bên phải chọn ngày dự báo, nhiệt độ đếm số, mô tả và 4 gauge (gió, ẩm, mưa, cảm giác). Phím trái/phải đổi ngày (hoặc đổi tháng khi rê trên lịch). Dải lịch học tuỳ chọn ở dưới lấy từ `features.clock.scheduleCommand` |
| Mạng (network) | top-right, 900×700 | Radar: lõi tròn cho mạng/thiết bị đang kết nối (giữ để ngắt); thẻ 170×60 bay theo quỹ đạo cho mạng/thiết bị lân cận (giữ để kết nối); "Current Device" chuyển sang thông tin chi tiết nối với lõi bằng tia năng lượng. Nhiều thiết bị Bluetooth thì các lõi xoay quanh tâm. Dưới cùng: tab Wi-Fi/Bluetooth (phím Tab) và nút nguồn |
| Âm lượng (volume) | top-right, 480×760 | Gauge tròn chất lỏng của thiết bị mặc định (bấm để tắt tiếng), tên, thanh master; tab Outputs/Inputs/Streams; thẻ thiết bị (bấm để đặt mặc định) hoặc stream, mỗi thẻ có nút tắt tiếng và thanh riêng |
| Pin (battery) | top-right, 480×760 | Thời gian máy chạy, nút đăng xuất; lõi pin trong vòng radar với vòng gradient theo mức và hiệu ứng khi rê chuột; thanh độ sáng và âm lượng; 4 nút giữ để xác nhận (khoá, ngủ, khởi động lại, tắt máy; lệnh cấu hình trong `features.battery`); chọn chế độ nguồn Perform/Balance/Saver |

Nếu API Quickshell khác tên trên phiên bản đang cài, chỉ sửa trong service tương ứng.

### 4.3 Giai đoạn sau

`launcher` (center, 800×700), `clipboard` (center, 800×700), `notifications` (overlay + trung tâm thông báo), OSD âm lượng, `lock`, `wallpaper` (+ matugen), `settings`. Thiết kế chi tiết từng popup bổ sung khi tới giai đoạn tương ứng, dựa trên popup v1.

## 5. Luồng dữ liệu

```
shell.json ─► Config ─► FeatureLoader nạp features/<tên>/feature.qml cho mỗi tên trong bar/enabled
                     ─► Bar dựng BarZone → BarGroup → barWidget của từng feature
UPower ─► BatteryService ─► BatteryWidget (bar) + BatteryPopup
PipeWire ─► core/services/Audio ─► VolumeWidget, VolumePopup, BatteryPopup (thanh âm lượng)
Bấm BluetoothWidget ─► openPopup("network", "bt") ─► ShellState.toggle ─► PopupHost ─► NetworkPopup (arg = "bt")
Hyprland IPC ─► core/services/Hypr ─► WorkspacesWidget, KeyboardWidget
Open-Meteo ─► core/services/Weather ─► WeatherWidget, CalendarPopup
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
| Lệnh ngoài thất bại (nmcli, powerprofilesctl, brightnessctl, easyeffects) | Service cảnh báo, giữ trạng thái cũ |
| Wifi cần mật khẩu mà chưa có profile đã lưu | Cảnh báo trong log; popup không hỏi mật khẩu |
| Lệnh lịch học in JSON sai | Cảnh báo, giữ dữ liệu cũ |

## 7. Kiểm thử

- **Hàm thuần** (`ConfigValidator.js`, `CoreSchema.js`, `ScaleMath.js`, `PopupLayout.js`, `FeatureContract.js`, `WeatherLogic.js`, các `*Logic.js` của feature): test bằng `node --test` trong `tests/js/`. File JS dùng `.pragma library` nên chạy được cả trong QML lẫn Node.
- **Hợp đồng feature**: `tests/js/features.test.mjs` kiểm tra mọi `features/*/feature.qml`.
- **Quy tắc kiến trúc**: `tools/check.sh` chạy R1–R7.
- **Chạy thật**: `qs -p shell.qml` trong phiên Hyprland; Quickshell tự reload khi sửa file.
- Mỗi giai đoạn chỉ coi là xong khi `check.sh` qua và đã chạy thật trên Hyprland.

## 8. Lộ trình

| Giai đoạn | Nội dung | Kết quả |
|---|---|---|
| 1. Core | config + validator, theme, state, `Hypr`, ui, feature loader + hợp đồng, bar khung (slot rỗng), popup host (chưa có popup), `check.sh`, tests | ✅ Shell khởi động với bar rỗng, test qua |
| 2. Bar | features: workspaces, media, clock, weather, tray, keyboard, network, bluetooth, volume, battery (chỉ widget + service) | ✅ Bar dùng được hằng ngày |
| 3. Giao diện v1 + popup | nút launcher/notifications, bảng màu v1, popup nhạc (+ equalizer), lịch, mạng, âm lượng, pin | Code xong, test qua; **chưa chạy thật trên Hyprland** |
| 4. Popup giữa + hệ thống | launcher, clipboard, notifications, OSD volume | |
| 5. Hoàn thiện | lock, wallpaper + matugen, settings | |

Mỗi giai đoạn có kế hoạch triển khai riêng.

## 9. Ngoài phạm vi

- Compositor khác Hyprland; bar dọc.
- Widget Movies, updater, focustime, stewart, guide, cài đặt màn hình của v1.
- Âm thanh hiệu ứng của popup mạng v1 (file wav).
- Lấy màu chủ đạo từ ảnh bìa cho khung popup nhạc (v1 dùng ImageMagick); Zone-C dùng màu theme.
- Nhập mật khẩu wifi trong popup.
- Installer tự động, gói AUR, Nix. Giai đoạn đầu chạy trực tiếp bằng `qs -p`.
- Telemetry.
