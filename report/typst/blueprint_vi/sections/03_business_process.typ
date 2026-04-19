// ============================================================
// 03_business_process.typ — QUY TRÌNH NGHIỆP VỤ
// ============================================================
#import "../template.typ": placeholder, hline, diagram-placeholder

= QUY TRÌNH NGHIỆP VỤ

// ─────────────────────────────────────────────────────────
== BP-BUG-01: Quản lý Vòng đời Lỗi

=== Luồng Quy trình

#diagram-placeholder("BP-BUG-01: Quản lý Vòng đời Lỗi", "docs/diagrams/bp-bug-01-lifecycle.mmd")

=== Mô tả Quy trình

#table(
  columns: (1.5cm, 3cm, 1fr, 3cm),
  align: (center, left, left, left),
  [*Bước \#*], [*Tên Bước*], [*Mô tả Chi tiết*], [*Vai trò*],
  [1], [Tạo Lỗi],
    [Tester điều hướng Màn hình 0300 (từ ngữ cảnh dự án). Điền Tiêu đề, SAP Module, Ưu tiên, Mức độ nghiêm trọng, Loại Lỗi. BUG_ID được tự động tạo. STATUS tự động đặt thành `1` (New). TESTER_ID tự động đặt thành SY-UNAME.],
    [Tester / Manager],
  [2], [Tự động Phân công Developer],
    [Hệ thống truy vấn ZBUG_USER_PROJEC để tìm Developer trong cùng dự án + module. Chọn người có tải công việc < 5 và ít lỗi đang hoạt động nhất. Đặt STATUS → `2` (Assigned), DEV_ID = người dùng được chọn. Nếu không tìm thấy → STATUS = `W` (Waiting), Manager được thông báo qua email.],
    [Hệ thống (tự động)],
  [3], [Phân công Thủ công],
    [Nếu STATUS = `W`, Manager mở Popup Chuyển Trạng thái (Màn hình 0370), chọn Developer thủ công, đặt STATUS → `2`. Manager cũng có thể phân công trực tiếp từ bất kỳ trạng thái nào.],
    [Manager],
  [4], [Bắt đầu Làm việc],
    [Developer mở popup 0370, chuyển STATUS → `3` (In Progress). Developer có thể đặt `4` (Pending) nếu bị chặn.],
    [Developer],
  [5], [Sửa Lỗi],
    [Developer tải lên bằng chứng sửa lỗi (fix_report.xlsx qua ZBUG_EVIDENCE). Trạng thái phải có ít nhất 1 tệp bằng chứng. Chuyển STATUS → `5` (Fixed) qua popup 0370.],
    [Developer],
  [6], [Tự động Phân công Final Tester],
    [Hệ thống truy vấn ZBUG_USER_PROJEC để tìm Tester trong cùng dự án + module. Tải công việc = ĐẾM lỗi có status = `6`. Chọn Tester có tải công việc thấp nhất < 5. Đặt STATUS → `6`, VERIFY_TESTER_ID = tester được chọn. Nếu không tìm thấy → STATUS = `W`.],
    [Hệ thống (tự động)],
  [7], [Final Testing],
    [Tester được phân công xác minh bản vá. Mở popup 0370. *Đạt:* nhập TRANS_NOTE → STATUS = `V` (Resolved). *Không đạt:* nhập TRANS_NOTE → STATUS = `3` (trả về InProgress).],
    [Tester (Final)],
  [8], [Đã Giải quyết],
    [STATUS = `V` là trạng thái kết thúc. Không cho phép chuyển đổi thêm. Lỗi được coi là hoàn thành.],
    [—],
  [9], [Luồng Từ chối],
    [Developer có thể từ chối (`R`) với TRANS_NOTE bắt buộc. Manager tái phân công cho Developer khác → STATUS = `2`. Điều này được ghi lại trong ZBUG_HISTORY với Action = `RS`.],
    [Developer / Manager],
)

// ─────────────────────────────────────────────────────────
== BP-BUG-02: Popup Chuyển Trạng thái (Màn hình 0370)

=== Luồng Quy trình

#diagram-placeholder("BP-BUG-02: Popup Chuyển Trạng thái (Màn hình 0370)", "docs/diagrams/bp-bug-02-status-popup.mmd")

=== Mô tả Quy trình

#table(
  columns: (1.5cm, 3cm, 1fr, 3cm),
  align: (center, left, left, left),
  [*Bước \#*], [*Tên Bước*], [*Mô tả Chi tiết*], [*Vai trò*],
  [1], [Mở Popup], [Người dùng nhấp nút STATUS_CHG trên Màn hình 0300. CALL SCREEN 0370 STARTING AT col row. Các trường màn hình được điền từ bản ghi ZBUG_TRACKER hiện tại.], [Developer / Tester / Manager],
  [2], [Chọn Chuyển đổi], [Người dùng chọn trạng thái đích từ dropdown (NEW_STATUS). Các tùy chọn có sẵn phụ thuộc vào trạng thái hiện tại và vai trò người dùng. Hệ thống thực thi ma trận chuyển đổi.], [Developer / Tester / Manager],
  [3], [Điền Trường Bắt buộc], [Tùy thuộc vào chuyển đổi: điền DEVELOPER_ID, FINAL_TESTER_ID (qua F4), hoặc TRANS_NOTE (văn bản tự do). Nút tải lên có sẵn cho bằng chứng khi chuyển sang Fixed (5).], [Developer / Tester / Manager],
  [4], [Xác nhận], [Người dùng nhấp CONFIRM. Hệ thống kiểm tra: kiểm tra quyền hạn, trường bắt buộc, kiểm tra bằng chứng (cho → 5), kiểm tra TRANS_NOTE (cho → R, → V, → 3 từ 6). Nếu hợp lệ → cập nhật DB + ghi nhật ký + gửi email.], [Hệ thống],
  [5], [Kích hoạt Tự động Phân công], [Nếu chuyển sang Fixed (5): hệ thống tự động phân công Final Tester. Nếu → Assigned (2) từ trạng thái 1/W/4: hệ thống có thể tự động phân công hoặc dùng DEVELOPER_ID từ popup.], [Hệ thống (tự động)],
)

// ─────────────────────────────────────────────────────────
== BP-PRJ-01: Quản lý Dự án

=== Luồng Quy trình

#diagram-placeholder("BP-PRJ-01: Vòng đời Quản lý Dự án", "docs/diagrams/bp-prj-01-project.mmd")

=== Mô tả Quy trình

#table(
  columns: (1.5cm, 3cm, 1fr, 3cm),
  align: (center, left, left, left),
  [*Bước \#*], [*Tên Bước*], [*Mô tả Chi tiết*], [*Vai trò*],
  [1], [Tạo Dự án], [Manager mở Màn hình 0500 (từ Danh sách Dự án 0400, action: CREA_PRJ). Điền PROJECT_ID (CHAR 20), PROJECT_NAME, DESCRIPTION, START_DATE, END_DATE, NOTE. STATUS tự động đặt thành `1` (Opening).], [Manager],
  [2], [Phân công Nhóm], [Trên Màn hình 0500, Table Control TC_USERS hiển thị thành viên dự án. Manager dùng nút ADD_USER để thêm người dùng SAP với vai trò M/D/T. Dùng REMO_USR để xóa.], [Manager],
  [3], [Kích hoạt Dự án], [Manager thay đổi trạng thái → `2` (In Process). Bây giờ có thể tạo lỗi trong dự án này.], [Manager],
  [4], [Tìm kiếm Dự án], [Màn hình 0410 (Tìm kiếm Dự án) là màn hình khởi đầu. Người dùng điền bộ lọc (Project ID, Tên, Trạng thái) và nhấp Execute → Màn hình 0400 (Danh sách Dự án ALV).], [Tất cả Vai trò],
  [5], [Tải lên Dự án], [Manager tải lên tệp Excel (mẫu: ZTEMPLATE_PROJECT qua SMW0). Hệ thống phân tích qua TEXT_CONVERT_XLS_TO_SAP, kiểm tra và chèn hàng loạt vào ZBUG_PROJECT.], [Manager],
  [6], [Đóng Dự án], [Manager đặt STATUS → `3` (Done). Hệ thống kiểm tra: tất cả lỗi phải ở Resolved (V). Nếu có lỗi chưa đóng → thông báo lỗi, chuyển đổi bị chặn.], [Manager],
)

