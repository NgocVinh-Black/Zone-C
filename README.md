# Zone-C · nhánh `dell-XPS`

Nhánh này là **bản sao lưu máy Dell XPS** (hostname `arch-xps`, user `zone-c`) trước khi cài lại Arch Linux.
Nó gồm toàn bộ Zone-C, cộng thêm cấu hình hệ thống, danh sách gói, font và theme của máy, nằm trong
[`backup/dell-xps`](backup/dell-xps).

README gốc của Zone-C (giới thiệu, ảnh, phím tắt) nằm ở nhánh [`main`](https://github.com/NgocVinh-Black/Zone-C/tree/main).

---

## Khôi phục sau khi cài lại Arch

### 0. Cài Arch cơ bản

Cài Arch như bình thường (ví dụ bằng `archinstall`), với các điểm sau:

- Tạo user **`zone-c`** và cho vào nhóm `wheel` (dùng được `sudo`).
- Cài sẵn `git` và `base-devel`.
- Có mạng (NetworkManager).
- Không cần chọn desktop. Zone-C và SDDM sẽ được cài ở bước sau.

Khởi động vào tài khoản `zone-c` ở màn hình dòng lệnh (TTY).

### 1. Clone nhánh này về

Máy mới chưa có khóa SSH, nên clone bằng HTTPS:

```bash
sudo pacman -S --needed git base-devel
git clone -b dell-XPS https://github.com/NgocVinh-Black/Zone-C.git ~/Zone-C
cd ~/Zone-C
```

### 2. Khôi phục hệ thống

```bash
./backup/dell-xps/restore.sh
```

Script sẽ:

1. Chép cấu hình `/etc`: `pacman.conf` (bật multilib, Color, giữ `sof-firmware`), mirrorlist,
   `mkinitcpio.conf`, locale, bàn phím, SDDM, hostname `arch-xps`, múi giờ `Asia/Ho_Chi_Minh`.
2. Cài lại **toàn bộ gói chính thức** từ `lists/pkglist-native.txt`.
3. Cài **yay**, rồi cài các **gói AUR** (Chrome, VS Code, Viber, GitHub Desktop, ElegooSlicer…).
4. Chép **cấu hình home**: dotfile, `~/.config`, script trong `~/.local/bin`, font, ble.sh, dconf.
5. Bật lại **dịch vụ**: NetworkManager, bluetooth, sddm, fstrim, pipewire, `zv1-notify`…
6. Chạy `mkinitcpio -P`.

Trong lúc chạy, script sẽ hỏi mật khẩu `sudo` và hỏi xác nhận khi pacman hoặc yay cài gói.

### 3. Cài Zone-C

```bash
./install/install.sh
```

Chọn cài đặt mới và bật SDDM trong menu.

### 4. Chép lại cấu hình của bạn

Trình cài Zone-C có thể ghi đè một số file cấu hình bằng bản mặc định. Chạy lệnh sau để đưa cấu hình
của bạn về lại:

```bash
./backup/dell-xps/restore.sh configs
```

### 5. Khởi động lại

```bash
reboot
```

Đăng nhập ở màn hình SDDM `zone-thunder`. Máy sẽ giống như trước khi cài lại.

---

## Việc cần làm tay sau khi khôi phục

Các mục này **không có** trong bản sao lưu (cố ý):

| Mục | Cách làm |
|---|---|
| Khóa SSH cho GitHub | `ssh-keygen -t ed25519 -C "ngocvinh1923@gmail.com"`, rồi thêm `~/.ssh/id_ed25519.pub` vào GitHub → Settings → SSH keys |
| Chuyển repo sang SSH | `git -C ~/Zone-C remote set-url origin git@github.com:NgocVinh-Black/Zone-C.git` |
| Chrome và các trình duyệt | Đăng nhập Google để đồng bộ bookmark, mật khẩu, extension |
| VS Code, GitHub Desktop, Viber | Đăng nhập lại |
| Claude Code | `curl -fsSL https://claude.ai/install.sh \| bash`, rồi `claude` để đăng nhập |
| Hook con mèo float-cat | Thêm hook vào `~/.claude/settings.json` theo README nhánh `main` |
| Dữ liệu cá nhân | Chép lại Documents, Downloads, Pictures, Projects, Videos từ USB hoặc ổ ngoài nếu có |
| fstab | Không cần làm gì, vì archinstall tự tạo fstab mới. File cũ để tham khảo: `backup/dell-xps/etc/fstab` |

---

## Nội dung `backup/dell-xps`

```
backup/dell-xps/
├── backup.sh      # chụp lại trạng thái máy hiện tại vào thư mục này
├── restore.sh     # khôi phục (thêm "configs" để chỉ chép lại cấu hình home)
├── lists/         # danh sách gói, dịch vụ, font, thông tin hệ thống
├── etc/           # file cấu hình hệ thống trong /etc
└── home/          # dotfile, ~/.config, ~/.local, font, theme sddm-zone-thunder
```

### Cập nhật bản sao lưu

Nếu chỉnh thêm gì trên máy và muốn lưu lại:

```bash
cd ~/Zone-C
./backup/dell-xps/backup.sh
git add -A backup/dell-xps
git commit -m "Cập nhật bản sao lưu Dell XPS"
git push
```

## Giấy phép

Zone-C là tác phẩm phái sinh của [Serpantinum](https://github.com/ilyamiro/serpantinum) © ilyamiro,
phân phối theo [GNU AGPL-3.0](LICENSE.md).
