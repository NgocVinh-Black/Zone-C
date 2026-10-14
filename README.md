# Zone-C V2 · Frost Dark

![Zone-C V2](docs/assets/banner-v2.png)

Desktop shell cho Hyprland, viết bằng Quickshell — của **NgocVinh-Black**.

**V2** là bản thiết kế lại theo chủ đề **Frost Dark**: nền tuyết, kính mờ tối, màu nhấn xanh băng,
logo mới *Ice Bolt*. Bản V1 (chủ đề sấm sét xanh) vẫn nằm ở nhánh [`main`](https://github.com/NgocVinh-Black/Zone-C/tree/main).

## Có gì mới trong V2

- **Bảng màu Frost Dark mới** cho preset *Zone Frost*, là preset mặc định khi cài.
  Nền xám xanh đậm, chữ trắng băng, màu nhấn `#d6e6ec` với chữ tối trên nền nhấn.
  Tương phản chữ phụ được nâng lên để dễ đọc trên nền kính.
- **Bar dạng đảo nổi**: các mô-đun tách thành từng viên, gom thành 3 cụm
  - Trái: nút Zone-C · workspace dạng viên · nhạc
  - Giữa: ghi hình / hẹn giờ · đồng hồ · thời tiết
  - Phải: khay hệ thống · cụm bộ gõ, Wi-Fi, Bluetooth, âm lượng, pin
- **Bỏ dock mặc định**: mở ứng dụng bằng launcher (`Super`), giống cách dùng Hyprland thuần.
  Vẫn bật lại được trong Cài đặt → Dock.
- **Bo góc 14px** cho panel, popup và nút.
- **Logo mới Ice Bolt**: khung tinh thể băng lục giác, chữ C là vòng cung hở, chữ Z là tia sét cắt qua,
  tia lấp lánh băng ở góc. File gốc vector nằm trong [`src/assets/logo`](src/assets/logo)
  (`zone-c-ice-bolt.svg` bản màu, `zone-c-ice-bolt-mono.svg` bản đơn sắc dùng `currentColor`).
- **Chế độ sáng Frost Light** giữ nguyên, chuyển nhanh bằng nút trong bảng hệ thống hoặc lệnh
  `quickshell ipc call zonetheme mode toggle`.
- **Cài một nhánh bất kỳ bằng lệnh một dòng** qua biến `ZONE_C_BRANCH` (xem phần cài đặt).

### Bảng màu Frost Dark

| Token | Màu | Dùng cho |
|---|---|---|
| `crust` | `#1c2428` | Nền sâu nhất, thanh bên |
| `mantle` | `#232d32` | Nền cửa sổ |
| `base` | `#2a353b` | Nền panel, viên bar |
| `surface0` / `surface1` / `surface2` | `#34424a` / `#415058` / `#53646d` | Ô, nút, đường kẻ |
| `text` | `#edf3f6` | Chữ chính |
| `subtext1` / `subtext0` | `#c6d3d9` / `#a7b8c1` | Chữ phụ |
| `blue` (màu nhấn) | `#d6e6ec` | Mục đang chọn, công tắc bật, nút chính |
| `sapphire` / `teal` | `#9fd3e0` | Ánh sáng băng, viền focus |
| `green` / `yellow` / `red` | `#a6dcbc` / `#ecdcaa` / `#ff7b7b` | Trạng thái tốt / cảnh báo / lỗi |

## Giao diện

- **Bar** ở cạnh trên (đổi được sang trái / phải / dưới): workspace, nhạc, đồng hồ, thời tiết, mạng,
  Bluetooth, âm lượng, pin và nút chuyển gõ tiếng Việt (`VI` / `US`).
- **Launcher** tìm ứng dụng, gõ `>` để chạy lệnh. Tự tắt Unikey khi mở để gõ tìm kiếm.
- **Bảng hệ thống**: âm lượng, độ sáng, nút bật nhanh, thông báo, nút nguồn, pin và chế độ nguồn.
- **Trình phát nhạc** kèm equalizer, cột cava nhảy theo nhạc.
- **Lịch và thời tiết**, **chọn hình nền**, **clipboard**, **chụp / quay màn hình**, **quick actions**, **polkit**.
- **Màn hình khóa** và **SDDM** dùng chung hình nền và màu của theme đang chọn.
- **Theme** có sẵn: *Zone Frost* (mặc định V2), *Zone Thunder*, *Zone Crystal* và hơn 90 bảng màu khác.
- **Terminal foot** đổi màu theo theme, banner Zone-C + fastfetch khi mở.
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
| `Super + Shift + K` / phím Copilot | Bật / tắt con mèo float-cat |
| `Super + K` | Rồi kéo con mèo bằng chuột để dời chỗ |

## Con mèo float-cat (Claude Code)

Con mèo nổi ở góc màn hình, hiện trên mọi workspace, không chặn chuột. Màu tự đổi theo theme đang dùng
(bản băng khi dùng Zone Frost).

Khi dùng [Claude Code](https://claude.com/claude-code), con mèo cho biết Claude đang làm gì:
khung suy nghĩ `• • •` khi đang chạy, dấu ✓ kèm nhảy lên khi xong, "Cần bạn nè!" khi chờ bạn duyệt.

Script cài đặt chép con mèo vào `~/.local/share/float-cat` và lệnh `float-cat` vào `~/.local/bin`.
Để con mèo đi theo Claude Code, thêm các hook sau vào `~/.claude/settings.json` (gộp với `hooks` đang có):

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
Xoá `~/.local/state/float-cat/pos.json` để đưa con mèo về góc phải dưới.

## Cài đặt V2 (Arch Linux và các bản dựa trên Arch)

Lệnh một dòng, cài nhánh V2:

```bash
ZONE_C_BRANCH=Zone-c-V2 bash -c "$(curl -fsSL https://raw.githubusercontent.com/NgocVinh-Black/Zone-C/Zone-c-V2/install/install.sh)"
```

Hoặc clone nhánh V2 về rồi chạy:

```bash
git clone -b Zone-c-V2 https://github.com/NgocVinh-Black/Zone-C.git
cd Zone-C
./install/install.sh
```

Đang dùng V1 và muốn lên V2: chạy một trong hai lệnh trên rồi chọn "update".
Cài đặt của bạn trong `~/.config/zone-c/settings.json` được giữ nguyên; để nhận bảng màu V2,
vào Cài đặt → Giao diện và chọn lại preset **Zone Frost**.

Muốn quay về V1: cài lại từ nhánh `main` (bỏ biến `ZONE_C_BRANCH`).

Cấu hình mẫu cho các compositor khác (niri, sway) nằm trong thư mục [compositors](compositors).

## Giấy phép

Zone-C là tác phẩm phái sinh của [Serpantinum](https://github.com/ilyamiro/serpantinum) © ilyamiro,
phân phối theo [GNU AGPL-3.0](LICENSE.md).
Mọi bản phân phối lại hoặc chỉnh sửa tiếp theo cũng phải giữ giấy phép AGPL-3.0 và ghi công các tác giả.
