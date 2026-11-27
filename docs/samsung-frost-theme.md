# Theme Zone-C Frost cho điện thoại Samsung

Công thức để một máy Samsung (One UI) trông giống hai máy đã làm: **Galaxy S22 Ultra (SM-S908U1)** và **Galaxy S25+ (SM-S936B)**, ngày 24/10/2026.
Màu lấy từ ảnh chụp panel hệ thống thật của desktop Zone-C (Frost dark), không phải đoán.

## Kết quả cần đạt

| Phần | Làm gì |
|---|---|
| Hình nền (màn hình chính + khóa) | Ảnh thành phố đêm của desktop, cắt dọc theo khổ màn hình máy |
| Thanh điều khiển nhanh | Theme Park → Quick panel `ZoneCFrostQP4` |
| Bàn phím Samsung | Theme Park → Keyboard `ZoneCFrostKB2` |
| Bảng âm lượng | Theme Park → Volume panel `ZoneCFrostVol2` |
| Cài đặt / app hệ thống | **Không** dùng theme Theme Park — giữ giao diện tối mặc định |
| Icon app | **Mặc định** — không gói icon, không Duotone, không "Áp dụng bảng màu cho biểu tượng" |
| Chế độ | Dark mode bật |

Không làm (đã thử và bị bỏ):
- **Theme hệ thống của Theme Park**: icon trong Cài đặt luôn vẽ hình màu trắng trên vòng tròn màu Primary. Primary băng `#D6E6EC` thì icon gần như không thấy; Primary tối thì công tắc đang bật bị chìm. Không có mục màu nào đổi được màu hình icon.
- **Icon app tùy chỉnh** (Duotone, Arcticons, ô icon tự vẽ): chủ máy không thích, giữ icon gốc.
- **Widget KWGT**: không dùng.

## Chuẩn bị máy

1. Cài đặt → Bảo mật và quyền riêng tư → **Trình chặn tự động**: tắt (ít nhất "Chặn lệnh qua cáp USB").
2. Bật Tùy chọn nhà phát triển (bấm Số hiệu bản tạo 7 lần) → **Gỡ lỗi USB**.
3. Cắm cáp, trên máy bấm **Cho phép** ("Luôn cho phép từ máy tính này"). `adb devices` phải ra `device`, không phải `unauthorized`.
4. Galaxy Store → cài **Good Lock**, trong Good Lock cài **Theme Park** (chủ máy tự bấm đồng ý điều khoản Galaxy Store).
5. Làm xong: bật lại Trình chặn tự động, tắt Gỡ lỗi USB.

## Hình nền

Ảnh gốc trên laptop: `~/Pictures/Wallpapers/ddg_1_1787483190574252591.jpg` (3840×2400). Cắt một dải dọc từ x=1500, làm tối ×0.85 như desktop, đúng độ phân giải máy (`adb shell wm size`):

```bash
W=~/Pictures/Wallpapers/ddg_1_1787483190574252591.jpg
read SW SH < <(adb shell wm size | awk -F'[ x]' '/Physical/{print $3, $4}')
CW=$(( 2400 * SW / SH ))
magick "$W" -crop ${CW}x2400+1500+0 +repage -resize ${SW}x${SH}! -evaluate multiply 0.85 -quality 95 zone-c-frost-phone.jpg
adb shell mkdir -p /sdcard/Pictures/Zone-C
adb push zone-c-frost-phone.jpg /sdcard/Pictures/Zone-C/
adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Pictures/Zone-C/zone-c-frost-phone.jpg
```

Đặt hình nền: mở ảnh trong Bộ sưu tập → ⋮ → Đặt làm hình nền → **Màn hình khóa và màn hình chờ**. (Qua ADB: `am start -a android.intent.action.ATTACH_DATA -d content://media/external/images/media/<id> -t image/jpeg --grant-read-uri-permission -n com.samsung.android.app.dressroom/.presentation.SetAsWallPaperActivity` — trên S22 chạy được, trên S25+ không mở.)

## Màu Theme Park

Trong Theme Park: tab → **Create new** → chọn màu chính bằng ô bút chì → bấm từng chấm màu trên bản xem trước để nhập mã (ô hex trong bảng màu, 8 ký tự = AARRGGBB có độ trong suốt). Bảng dưới theo thứ tự chấm như uiautomator liệt kê; vị trí nút lệch theo máy nên **dò bằng giá trị màu hiện tại** (cột "mặc định") chứ đừng tin tọa độ.

### Quick panel → `ZoneCFrostQP4`

Màu chính (ô to đầu hàng): `232A2F`. Trang 1:

| Vùng | Mặc định (để nhận ra) | Mã Frost |
|---|---|---|
| Nền toàn panel (có Transparency) | `CC79B2CF`-kiểu | `F7232A2F` |
| Nút đang bật (nền) | `FF587E77`-kiểu | `FFD6E6EC` |
| Icon trên nút bật | `FFFFFF` (chấm trên cùng, gần Wi-Fi) | `162025` |
| Nút đang tắt (nền) | `00587E77`-kiểu | `FF343C41` |
| Icon/chữ nút tắt | `FFFFFF` (chấm bên phải) | `C6D3D9` |
| Thanh trượt (phần đã kéo) | `FF587E77`-kiểu | `FFD6E6EC` |
| Nền các khối nhóm | `000000` | `2F373C` |

Trang 2 (chấm "2" trên cùng — thẻ thông báo):

| Vùng | Mặc định | Mã Frost |
|---|---|---|
| Nền thẻ thông báo | `FF283136` | `FF2D3438` |
| Chữ tiêu đề | `FFFFFF` | `EDF3F6` |
| Chữ phụ | `FFFFFFFF` | `FFC6D3D9` |

### Keyboard → `ZoneCFrostKB2`

Màu chính: `232A2F`.

| Vùng | Mặc định | Mã Frost |
|---|---|---|
| Nền bàn phím | `FF283136` | `FF232A2F` |
| Icon thanh công cụ | `FFFFFF` (hàng trên) | `C6D3D9` |
| Nền thanh công cụ | `010101` | `232A2F` |
| Chữ phím | `FFFFFF` | `EDF3F6` |
| Phím đang nhấn | `8079B2CF` | `80D6E6EC` |
| Ký tự phụ trên phím | `FFFFFF` | `C6D3D9` |
| Phím chức năng (Shift, !#1…) | `80283136` | `FF262D32` |
| Chữ phím cách | `FFFFFF` | `C6D3D9` |
| Phím thường | `80283136` | `FF2D3438` |

### Volume panel → `ZoneCFrostVol2`

Màu chính: `232A2F`.

| Vùng | Mặc định | Mã Frost |
|---|---|---|
| Nền panel | `FF010101` | `F7232A2F` |
| Chữ tiêu đề | `FFFFFF` | `EDF3F6` |
| Rãnh thanh trượt | `80283136` | `FF1D2327` |
| Phần đã kéo | `FF587E77` | `FFD6E6EC` |
| Icon trên thanh | `FFFFFF` | `162025` |
| Icon đang bật / tắt tiếng | `DD2C00` | `162025` |

Lưu: nút lưu góc phải trên → nhập tên → OK → bấm vào bản vừa lưu → **Apply**.

## Lưu ý khi làm

- Áp dụng (hoặc bỏ) một **Theme** trong Theme Park sẽ **tắt** Quick panel / Keyboard / Volume — phải bấm Apply lại ba phần đó. Vì không dùng Theme nên bình thường không gặp, trừ khi máy đã có sẵn theme.
- Theme Park **không ghi đè** bản đang áp dụng: lưu tên mới → Apply → xóa bản cũ. Mỗi tab chỉ giữ đúng một bản.
- Mở lại bước chọn **màu chính** của một bản đã có sẽ **reset** các màu chi tiết — nhập lại hết.
- Theme Park không có nút xuất; Smart Switch nhiều khả năng không mang theo các bản này — làm lại trên máy mới theo file này.
- Kết nối ADB có thể rớt sang `unauthorized` giữa chừng (cáp lỏng, Trình chặn tự động bật lại): cho phép lại trên máy rồi làm tiếp, kiểm tra lại màu đã nhập.

## Hai bảng màu nguồn (desktop Frost dark)

| Vai trò | Mã | Đo từ |
|---|---|---|
| Nền panel | `#232A2F` | nền panel hệ thống desktop |
| Ô tắt / khối | `#262D32` | ô Night light, Caffeine |
| Thẻ | `#2D3438` | thẻ thông báo |
| Ô icon | `#34424A` | ô chuông trong thông báo |
| Rãnh thanh trượt | `#1D2327` | thanh âm lượng/độ sáng |
| Đang bật | `#D6E6EC` | Wi-Fi, Bluetooth đang bật, thanh trượt |
| Chữ trên nền bật | `#162025` | |
| Chữ chính / phụ | `#EDF3F6` / `#C6D3D9` | |
| Đỏ | `#FF7B7B` | nút nguồn |
