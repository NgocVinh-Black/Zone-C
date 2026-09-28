# Zone-C

Desktop shell cho Hyprland (Quickshell) — bản tùy biến của **NgocVinh-Black**.

> Zone-C được phát triển dựa trên [Serpantinum](https://github.com/ilyamiro/serpantinum) của **ilyamiro**,
> phát hành theo giấy phép [GNU AGPL-3.0](LICENSE.md). Toàn bộ lịch sử commit của dự án gốc được giữ nguyên trong repo này.

## Previews

| | |
|---|---|
| ![Preview 1](docs/assets/previews/preview_1.png) | ![Preview 2](docs/assets/previews/preview_2.png) |
| ![Preview 3](docs/assets/previews/preview_3.png) | ![Preview 4](docs/assets/previews/preview_4.png) |

## Khác biệt so với Serpantinum

- Đổi tên toàn bộ thành **Zone-C** (`zone-c`, `zone-cd`, `~/.local/share/zone-c`, `~/.config/zone-c`).
- Gõ tiếng Việt bằng **fcitx5 + Unikey**: nút bàn phím trên bar bật/tắt Unikey (hiện `VI` / `US`),
  launcher tự tắt Unikey khi mở để ô tìm kiếm nhận chữ.
- Bộ phím tắt Hyprland riêng (`Super+/` để xem bảng phím tắt), `Super+Q` đóng panel trước rồi mới đóng cửa sổ.
- Icon Papirus-Dark qua qt6ct, màn hình laptop scale 2.
- Tắt telemetry của installer.

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

Zone-C là tác phẩm phái sinh của Serpantinum © ilyamiro, phân phối theo [GNU AGPL-3.0](LICENSE.md).
Mọi bản phân phối lại hoặc chỉnh sửa tiếp theo cũng phải giữ giấy phép AGPL-3.0 và ghi công các tác giả.
