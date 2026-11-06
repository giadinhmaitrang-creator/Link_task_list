# Kho Link Dự Án

Web app lưu trữ và quản lý link website, tài liệu theo **dự án** và **nhóm** do bạn tự đặt (theo tính năng, hạng mục hoặc giai đoạn).

## Tính năng

- Danh mục dạng cây: dự án → nhóm tài liệu, kèm số lượng.
- Danh sách tài liệu mới thêm, chia theo mốc thời gian, có tab theo dự án.
- Sắp xếp: mới thêm, cũ nhất, mới cập nhật, tên A–Z, theo nhóm, theo loại.
- Tự nhận diện loại link từ URL (Google Docs/Sheets/Slides, Figma, GitHub, PDF, Drive, YouTube…); bộ loại link chỉnh sửa được.
- Thêm nhiều link một lần (mỗi dòng một link, hoặc `Tiêu đề | URL`).
- Ghim, tag, ghi chú, cảnh báo link trùng.
- Chọn nhiều tài liệu để đổi loại, chuyển nhóm, chuyển dự án hoặc xóa.
- Giao diện sáng/tối, dùng được trên điện thoại.

## Lưu trữ dữ liệu

Dữ liệu được lưu trong **bộ nhớ trình duyệt (localStorage)** của máy đang dùng:

- Không cần tài khoản hay máy chủ.
- Dữ liệu **không** tự đồng bộ giữa các máy hoặc trình duyệt khác nhau.
- Xóa dữ liệu duyệt web hoặc dùng chế độ ẩn danh sẽ mất dữ liệu.

Hãy dùng nút **Dữ liệu → Xuất dữ liệu (.json)** để sao lưu định kỳ, và **Nhập dữ liệu từ file** để khôi phục hoặc chuyển sang máy khác.

## Chạy

Toàn bộ app nằm trong một file `index.html`, không cần build.

- Online: bật GitHub Pages cho kho này (Settings → Pages → Deploy from a branch → `main` / root).
- Trên máy: mở trực tiếp `index.html` bằng trình duyệt.
