
## Các lỗi còn tồn tại

1. Khi vào phần chi tiết Bug, nhấn vào các nút Description, Dev Note, Tester Note thì bị short dump.

   *Minh họa: dump `CALL_FUNCTION_CONFLICT_TYPE` / `READ_TEXT` / `LOAD_LONG_TEXT` (Z_BUG_WORKSPACE_MP).*

   ![Short dump khi mở tab văn bản dài — 11:58](./runtime-error-read-text-type-conflict-115802.png)

2. Ô nhập Description cần là một box lớn, riêng biệt.

   *Minh họa: màn Create Bug — nội dung mô tả nằm chung khu vực Bug Info thay vì ô/tab Description riêng.*

   ![Create Bug — mô tả trong Bug Info](./create-bug-bug-info-status-3-no-upload.png)

   ![Create Project — ô Description (tham chiếu layout ô nhập)](./create-project-testing-new-tester.png)

3. Description đang bị giới hạn số lượng ký tự cho phép nhập.

   *Minh họa: form project với đoạn mô tả dài (ZBUG_HOME, đơn hàng lớn…).*

   ![Project — Description dài](./create-project-long-description.png)

4. Hiển thị chữ bị thiếu ở một số trường.

   *Minh họa: Display Bug BUG0000023 — một số trường trống (SAP Module, Severity, Created Date…).*

   ![Display Bug BUG0000023 — metadata thiếu](./display-bug-bug0023-empty-metadata.png)

5. Khi không chọn user nào nhưng lại nhấn "Remove User" thì vẫn thực hiện xóa user.

   *Minh họa: luồng Remove user trên Change Project (popup xác nhận xóa DEV-061); popup gán user.*

   ![Xác nhận Remove user](./change-project-remove-user-confirm.png)

   ![Assign User to Project](./change-project-assign-user-popup.png)

6. Tại màn hình tạo bug:
   - Trường Status luôn phải là 1, người dùng không được phép chọn giá trị khác.
   - SAP Module cần có Search Help.
   - Phải có nút "Upload Evidence 1" ngay tại màn hình tạo bug.
   - Ngày tạo (Create date) tự động sinh, không cho người dùng nhập.

   *Minh họa: Status = 3, SAP Module trống / sau điền MM, Created Date trống, không thấy Upload Evidence trên Bug Info.*

   ![Create Bug — Status 3, thiếu upload evidence, Create date trống](./create-bug-bug-info-status-3-no-upload.png)

   ![Create Bug — lỗi validate Severity/Priority (footer)](./create-bug-validation-error-footer.png)

7. Sau khi nhập liệu bị lỗi, các trường nhập liệu đều bị khóa hoàn toàn, người dùng không thể sửa lại.

   *Minh họa: cùng màn Create Bug sau khi có thông báo lỗi ở status bar.*

   ![Create Bug — thông báo lỗi validate](./create-bug-validation-error-footer.png)

8. Dữ liệu Description biến mất khi vào xem chi tiết bug.

   *Minh họa: Display Bug — vùng text lớn trống; BUG0000024 Bug Info.*

   ![Display Bug BUG0000023](./display-bug-bug0023-empty-metadata.png)

   ![Display Bug BUG0000024](./display-bug-bug0024-bug-info.png)

9. Ở màn hình Change Bug:
    - Các nút Description, Dev Note, Tester Note đều bị lỗi short dump.
    - Riêng ở màn hình Create Bug thì nhấn vào các nút này không bị lỗi nhưng cũng không hiện nội dung gì.

   *Minh họa: dump khi tải long text (thời điểm 12:33); Create Bug chỉ có tab, nội dung tab chưa thấy trong ảnh Bug Info.*

   ![Short dump READ_TEXT — 12:33](./runtime-error-read-text-type-conflict-123322.png)

   ![Create Bug — các tab Description / Dev Note / Tester Note](./create-bug-bug-info-status-3-no-upload.png)

10. Có thể chuyển Bug Status từ 3 về 1 mà không có thông báo lỗi.

    *Minh họa: BUG0000024 trước đó In Progress (3), sau lưu thành New (1).*

    ![Change Bug — Status 3 In Progress](./change-bug-bug0024-status-in-progress.png)

    ![Change Bug — Status 1 New, đã lưu](./change-bug-bug0024-status-1-new-saved.png)

    ![Change Bug — Bug Info (thêm góc nhìn)](./change-bug-bug0024-bug-info-alt.png)

11. Bug có thể chuyển từ trạng thái này sang trạng thái khác mà không cần evidence hoặc cảnh báo lỗi, sai logic.

    *Minh họa: BUG0000024 chuyển sang Fixed (5) và lưu thành công.*

    ![Change Bug — Status 5 Fixed, đã lưu](./change-bug-bug0024-status-5-fixed-saved.png)
