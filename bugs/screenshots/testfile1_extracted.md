# Nội dung trích từ testfile1.docx

## Các vấn đề đã ghi nhận

1. Sửa lại UI display thông số cho đẹp hơn.
2. Header đang bị hiện cái title của 1 bug trong chương trình, dù đây là trang bug list. Đề xuất đổi sang title cố định.
3. Tài khoản **dev-061** (role dev) nhấn vào search help của new status không có giá trị.
4. Thử đổi status sang 5 (Fixed) mà không upload evidence:
    - Không thực hiện được
    - Không hiện message lỗi
5. Nút upload evidence không chạy, không thoát được màn hình đổi status, đang bị soft lock. Không thực hiện được thao tác gì khác, phải tắt cả SAP mới thoát được.
6. Màn hình detail có nút "change status" nhưng khi nhấn lại báo phải chuyển sang "change mode".
    - Đề xuất: Xóa nút "change status" ở màn hình detail.
7. Không đọc được note, không lưu được note.
8. Tạo bug mới nhưng cũng không save được note.
9. Đã thêm 1 dev test vào project nhưng trong detail project không hiện dev mới được thêm vào.
    - Chức năng add user hoạt động tốt nhưng không hiển thị.

---

## Hình ảnh minh họa

| STT | Ảnh                                  |
|-----|--------------------------------------|
|  1  | ![Image 1](./testfile1_images/bug-list-net-value-overview.png)   |
|  2  | ![Image 2](./testfile1_images/bug-list-header-net-value.png)   |
|  3  | ![Image 3](./testfile1_images/change-bug-0024-status-popup-new2.png)   |
|  4  | ![Image 4](./testfile1_images/change-bug-0024-status-popup-new5.png)   |
|  5  | ![Image 5](./testfile1_images/change-bug-0024-status-popup-fixed-note.png)   |
|  6  | ![Image 6](./testfile1_images/display-bug-0028-bug-info.png)   |
|  7  | ![Image 7](./testfile1_images/change-bug-0024-note-saved.png)   |
|  8  | ![Image 8](./testfile1_images/bug-list-warning-could-not-read-description.png)   |
|  9  | ![Image 9](./testfile1_images/change-bug-0025-file-upload-success.png)   |
| 10  | ![Image 10](./testfile1_images/display-bug-0025-status-waiting.png) |
| 11  | ![Image 11](./testfile1_images/change-project-net-value-details.png) |
| 12  | ![Image 12](./testfile1_images/zbug-user-projec-table-entries.png) |
