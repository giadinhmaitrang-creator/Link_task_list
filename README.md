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
- **Quản lý công việc dạng Kanban** (như Trello), với danh mục **Bảng** riêng, độc lập với dự án tài liệu:
  - cột trạng thái tùy chỉnh (mặc định: Cần làm, Đang làm, Chờ duyệt, Hoàn thành), kéo-thả thẻ giữa các cột;
  - thẻ có ưu tiên, ngày bắt đầu, hạn chót (báo quá hạn / sắp đến hạn), nhãn màu, checklist, mô tả, người phụ trách;
  - đính kèm tài liệu từ bất kỳ dự án nào vào thẻ;
  - lọc theo ưu tiên, hạn, nhãn; lưu trữ và khôi phục thẻ;
  - trang “Việc cần chú ý” gom việc quá hạn và sắp đến hạn của mọi bảng.
- **Lịch (chỉ xem)**: lấy lịch về để xem cùng công việc, không ghi ngược lại.
  - Google Calendar cá nhân: đăng nhập Google với quyền chỉ đọc (`calendar.readonly`), tự cập nhật. Cần tạo Client ID trên Google Cloud (hướng dẫn trong *Lịch → Cài đặt lịch*), origin: `https://giadinhmaitrang-creator.github.io`.
  - Outlook công ty: nhập file `.ics` xuất từ Outlook (hỗ trợ lịch lặp, ngoại lệ, múi giờ).
  - Lịch theo ngày, khối “Lịch hôm nay” trong *Việc cần chú ý*, số cuộc họp trên thẻ có hạn chót.
  - Không nằm trong file xuất dữ liệu; khi bật Đồng bộ GitHub thì lịch (sự kiện Gmail đã lấy về, Client ID, lịch Outlook đã nhập) được đồng bộ sang các máy khác. Cài đặt ẩn/hiện lịch vẫn riêng từng máy.
- **Đồng bộ nhiều máy qua kho GitHub riêng tư**: dữ liệu lưu thành `data.json` trong một kho *private* của bạn (ví dụ `Link_task_data`), dùng fine-grained token chỉ có quyền *Contents* với đúng kho đó. Tự lưu sau mỗi thay đổi, tự tải bản mới khi mở trang, gộp khi hai máy cùng sửa, có lịch sử phiên bản. Web từ chối đồng bộ nếu kho dữ liệu là công khai.
- Giao diện sáng/tối, dùng được trên điện thoại.

## Lưu trữ dữ liệu

Dữ liệu được lưu trong **bộ nhớ trình duyệt (localStorage)** của máy đang dùng:

- Không cần tài khoản hay máy chủ.
- Dữ liệu **không** tự đồng bộ giữa các máy hoặc trình duyệt khác nhau.
- Xóa dữ liệu duyệt web hoặc dùng chế độ ẩn danh sẽ mất dữ liệu.

Hãy dùng nút **Dữ liệu → Xuất dữ liệu (.json)** để sao lưu định kỳ, và **Nhập dữ liệu từ file** để khôi phục hoặc chuyển sang máy khác.

## Chạy

Toàn bộ app nằm trong `index.html`, kèm thư viện kéo-thả [SortableJS](https://github.com/SortableJS/Sortable) 1.15.2 (MIT) trong `vendor/`. Không cần build.

- Online: https://giadinhmaitrang-creator.github.io/Link_task_list/ (GitHub Pages, chạy từ nhánh `gh-pages`).
- Cập nhật web: sửa `index.html` trên `main`, rồi đưa cùng nội dung sang nhánh `gh-pages`: `git push origin main:gh-pages`.
- Trên máy: mở trực tiếp `index.html` bằng trình duyệt.
